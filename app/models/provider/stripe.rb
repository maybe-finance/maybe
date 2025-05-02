class Provider::Stripe
  def initialize(secret_key:, webhook_secret:)
    @client = Stripe::StripeClient.new(
      secret_key,
      stripe_version: "2025-04-30.basil"
    )
    @webhook_secret = webhook_secret
  end

  def process_event(event_id)
    event = retrieve_event(event_id)

    case event.type
    when /^customer\.subscription\./
      SubscriptionEventProcessor.new(event: event, client: client).process
    when /^customer\./
      CustomerEventProcessor.new(event: event, client: client).process
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end
  end

  def process_webhook_later(webhook_body, sig_header)
    thin_event = client.parse_thin_event(webhook_body, sig_header, webhook_secret)

    if thin_event.type.start_with?("customer.")
      StripeEventHandlerJob.perform_later(thin_event.id)
    else
      Rails.logger.info "Unhandled event type: #{thin_event.type}"
    end
  end

  def create_customer(email:, metadata: {})
    client.v1.customers.create(
      email: email,
      metadata: metadata
    )
  end

  def get_checkout_session_url(price_id:, customer_id: nil, success_url: nil, cancel_url: nil)
    client.v1.checkout.sessions.create(
      customer: customer_id,
      line_items: [ { price: price_id, quantity: 1 } ],
      mode: "subscription",
      allow_promotion_codes: true,
      success_url: success_url,
      cancel_url: cancel_url
    ).url
  end

  def get_billing_portal_session_url(customer_id:, return_url: nil)
    client.v1.billing_portal.sessions.create(
      customer: customer_id,
      return_url: return_url
    ).url
  end

  def retrieve_checkout_session(session_id)
    client.v1.checkout.sessions.retrieve(session_id)
  end

  private
    attr_reader :client, :webhook_secret

    def retrieve_event(event_id)
      client.v1.events.retrieve(event_id)
    end
end
