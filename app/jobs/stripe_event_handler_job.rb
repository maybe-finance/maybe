class StripeEventHandlerJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    stripe_provider = Provider::Registry.get_provider(:stripe)
    Rails.logger.info "Processing Stripe event: #{event_id}"
    stripe_provider.process_event(event_id)
  end
end
