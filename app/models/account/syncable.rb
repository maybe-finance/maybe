module Account::Syncable
    extend ActiveSupport::Concern

    def sync_later
        AccountSyncJob.perform_later self
    end

    def sync
        update!(status: "SYNCING")
        synced_daily_balances = Account::BalanceCalculator.new(self).daily_balances
        self.balances.upsert_all(synced_daily_balances, unique_by: :index_account_balances_on_account_id_and_date)
        self.balances.where("date < ?", self.effective_start_date).delete_all
        update!(status: "OK")
    rescue => e
        update!(status: "ERROR")
        Rails.logger.error("Failed to sync account #{id}: #{e.message}")
    end
end
