class AutoDetectMerchantsJob < ApplicationJob
  queue_as :medium_priority

  def perform(family, transaction_ids: [])
    family.auto_detect_transaction_merchants(transaction_ids)
  end
end
