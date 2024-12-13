class EnrichDataJob < ApplicationJob
  queue_as :default

  def perform(account)
    account.enrich_data
  end
end
