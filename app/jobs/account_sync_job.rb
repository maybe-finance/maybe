class AccountSyncJob < ApplicationJob
  queue_as :default

  def perform(account_id:)
    account = Account.find(account_id)
    account.update!(status: "SYNCING")

    begin
      AccountSyncer.new(account).sync
      account.update!(status: "OK")
    rescue => e
      account.update!(status: "ERROR")
      Rails.logger.error("Failed to sync account #{account_id}: #{e.message}")
    end
  end
end
