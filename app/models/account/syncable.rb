module Account::Syncable
  extend ActiveSupport::Concern

  def sync_later(start_date = nil)
    AccountSyncJob.perform_later(self, start_date)
  end

  def sync(start_date = nil)
    Account::Sync.start_or_resume(self, start_date)

    #   update!(status: "syncing")
    #
    #   balances.sync(self, start_date:)
    #
    #   update! \
    #     status: "ok",
    #     last_sync_date: Date.current,
    #     balance: self.balances.in_currency(self.currency).reverse_chronological.first&.balance,
    #     sync_errors: calculator.errors,
    #     sync_warnings: calculator.warnings
    # rescue => e
    #   update!(status: "error", sync_errors: [ :sync_message_unknown_error ])
    #   logger.error("Failed to sync account #{id}: #{e.message}")
  end

  def can_sync?
    # Skip account sync if account is not active or the sync process is already running
    return false unless is_active
    return false if syncing?
    # If last_sync_date is blank (i.e. the account has never been synced before) allow syncing
    return true if last_sync_date.blank?

    # If last_sync_date is not today, allow syncing
    last_sync_date != Date.today
  end

  # The earliest date we can calculate a balance for
  def effective_start_date
    @effective_start_date ||= entries.order(:date).first.try(:date) || Date.current
  end
end
