class AutoCategorizeJob < ApplicationJob
  queue_as :medium_priority

  def perform(family, transaction_ids: [])
    family.auto_categorize_transactions(transaction_ids)
  end
end
