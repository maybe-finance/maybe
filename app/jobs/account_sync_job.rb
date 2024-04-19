class AccountSyncJob < ApplicationJob
  queue_as :default

  def perform(account, start_date = nil)
    account.sync(start_date)
  end
end
