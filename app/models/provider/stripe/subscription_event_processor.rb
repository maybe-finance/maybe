class Provider::Stripe::SubscriptionEventProcessor < Provider::Stripe::EventProcessor
  Error = Class.new(StandardError)

  def process
    raise Error, "Family not found for Stripe customer ID: #{customer_id}" unless family

    family.update(
      stripe_plan_id: plan_id,
      stripe_subscription_status: subscription_status
    )
  end

  private
    def family
      Family.find_by(stripe_customer_id: customer_id)
    end

    def customer_id
      event_data.customer
    end

    def plan_id
      event_data.plan.id
    end

    def subscription_status
      event_data.status
    end
end
