class PlaidItemSyncJob < ApplicationJob
  queue_as :default

  def perform(plaid_item)
    plaid_item.sync
  end
end
