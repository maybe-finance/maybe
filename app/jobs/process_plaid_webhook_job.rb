class ProcessPlaidWebhookJob < ApplicationJob
  queue_as :default

  def perform(webhook_body)
    Provider::Plaid::WebhookProcessor.new(webhook_body).process
  end
end
