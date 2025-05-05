class Provider::Stripe
  Error = Class.new(StandardError)

  def initialize(secret_key:, webhook_secret:)
    @client = Stripe::StripeClient.new(secret_key)
    @webhook_secret = webhook_secret
  end

  def process_event(event_id)
    event = retrieve_event(event_id)

    case event.type
    when /^customer\.subscription\./
      SubscriptionEventProcessor.new(event).process
    else
      Rails.logger.warn "Unhandled event type: #{event.type}"
    end
  end

  def process_webhook_later(webhook_body, sig_header)
    thin_event = client.parse_thin_event(webhook_body, sig_header, webhook_secret)
    StripeEventHandlerJob.perform_later(thin_event.id)
  end

  def create_checkout_session(plan:, family_id:, family_email:, success_url:, cancel_url:)
    customer = client.v1.customers.create(
      email: family_email,
      metadata: {
        family_id: family_id
      }
    )

    session = client.v1.checkout.sessions.create(
      customer: customer.id,
      line_items: [ { price: price_id_for(plan), quantity: 1 } ],
      mode: "subscription",
      allow_promotion_codes: true,
      success_url: success_url,
      cancel_url: cancel_url
    )

    NewCheckoutSession.new(url: session.url, customer_id: customer.id)
  end

  def get_checkout_result(session_id)
    session = client.v1.checkout.sessions.retrieve(session_id)

    unless session.status == "complete" && session.payment_status == "paid"
      raise Error, "Checkout session not complete"
    end

    CheckoutSessionResult.new(success?: true, subscription_id: session.subscription)
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Error fetching checkout result for session #{session_id}: #{e.message}"
    CheckoutSessionResult.new(success?: false, subscription_id: nil)
  end

  def create_billing_portal_session_url(customer_id:, return_url:)
    client.v1.billing_portal.sessions.create(
      customer: customer_id,
      return_url: return_url
    ).url
  end

  def update_customer_metadata(customer_id:, metadata:)
    client.v1.customers.update(customer_id, metadata: metadata)
  end

  private
    attr_reader :client, :webhook_secret

    NewCheckoutSession = Data.define(:url, :customer_id)
    CheckoutSessionResult = Data.define(:success?, :subscription_id)

    def price_id_for(plan)
      prices = {
        monthly: ENV["STRIPE_MONTHLY_PRICE_ID"],
        annual: ENV["STRIPE_ANNUAL_PRICE_ID"]
      }

      prices[plan.to_sym || :monthly]
    end

    def retrieve_event(event_id)
      client.v1.events.retrieve(event_id)
    end
end
