class EnrichDataJob < ApplicationJob
  queue_as :latency_high

  def perform(account)
    account.enrich_data
  end
end
