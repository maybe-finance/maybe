class AccountSyncJob < ApplicationJob
  queue_as :default

  def perform(account)
    account.sync
  end
end
