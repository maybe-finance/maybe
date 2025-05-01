class Provider::Stripe::CustomerEventProcessor < Provider::Stripe::EventProcessor
  Error = Class.new(StandardError)

  def process
    raise Error, "Family not found for Stripe customer ID: #{customer_id}" unless family

    family.update(
      stripe_customer_id: customer_id
    )
  end

  private
    def family
      Family.find_by(stripe_customer_id: customer_id)
    end

    def customer_id
      event_data.id
    end
end
