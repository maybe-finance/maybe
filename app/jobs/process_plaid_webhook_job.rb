class ProcessPlaidWebhookJob < ApplicationJob
  queue_as :default

  def perform(webhook_body)
    # TODO
    puts webhook_body
    puts "Processing Plaid webhook..."
  end
end
