class SubscriptionManager
  def initialize(upgrade_url:, checkout_success_url:, billing_url:)
    @upgrade_url = upgrade_url
    @checkout_success_url = checkout_success_url
    @billing_url = billing_url
  end

  def get_checkout_result(session_id)
    session = stripe_provider.retrieve_checkout_session(session_id)

    unless session.status == "complete" && session.payment_status == "paid"
      raise Error, "Checkout session not complete"
    end

    CheckoutSessionResult.new(success?: true, subscription_id: session.subscription)
  rescue StandardError => e
    Sentry.capture_exception(e)
    Rails.logger.error "Error fetching checkout result for session #{session_id}: #{e.message}"
    CheckoutSessionResult.new(success?: false, subscription_id: nil)
  end

  def checkout_session_url(plan:, email:, family_id:)
    cancel_url = upgrade_url + "?plan=#{plan}"

    stripe_provider.create_checkout_session(
      price_id: price_id_for(plan),
      customer_email: email,
      success_url: checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancel_url,
      family_id: family_id
    ).url
  end

  def billing_portal_url_for(customer_id)
    stripe_provider.create_billing_portal_session(
      customer_id: customer_id,
      return_url: billing_url
    ).url
  end

  private
    attr_reader :upgrade_url, :checkout_success_url, :billing_url

    CheckoutSessionResult = Data.define(:success?, :subscription_id)

    def stripe_provider
      @stripe_provider ||= Provider::Registry.get_provider(:stripe)
    end

    def price_id_for(plan)
      prices = {
        monthly: ENV["STRIPE_MONTHLY_PRICE_ID"],
        annual: ENV["STRIPE_ANNUAL_PRICE_ID"]
      }

      prices[plan.to_sym || :monthly]
    end
end
