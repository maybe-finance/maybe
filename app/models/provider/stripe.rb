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

  def create_checkout_session(price_id:, family_id: nil, customer_email: nil, success_url: nil, cancel_url: nil)
    client.v1.checkout.sessions.create(
      customer_email: customer_email,
      line_items: [ { price: price_id, quantity: 1 } ],
      mode: "subscription",
      allow_promotion_codes: true,
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: {
        family_id: family_id
      }
    )
  end

  def retrieve_checkout_session(session_id)
    client.v1.checkout.sessions.retrieve(session_id)
  end

  def create_billing_portal_session(customer_id:, return_url: nil)
    client.v1.billing_portal.sessions.create(
      customer: customer_id,
      return_url: return_url
    )
  end

  private
    attr_reader :client, :webhook_secret

    def retrieve_event(event_id)
      client.v1.events.retrieve(event_id)
    end
end
