module Account::Syncable
    extend ActiveSupport::Concern

    def sync_later
        AccountSyncJob.perform_later self
    end

    def sync
        update!(status: "SYNCING")
        synced_daily_balances = Account::BalanceCalculator.new(self).daily_balances
        self.balances.upsert_all(synced_daily_balances, unique_by: :index_account_balances_on_account_id_and_date)
        self.balances.where("date < ?", effective_start_date).delete_all
        update!(status: "OK")
    rescue => e
        update!(status: "ERROR")
        Rails.logger.error("Failed to sync account #{id}: #{e.message}")
    end

    # The earliest date we can calculate a balance for
    def effective_start_date
        first_valuation_date = self.valuations.order(:date).pluck(:date).first
        first_transaction_date = self.transactions.order(:date).pluck(:date).first

        [ first_valuation_date, first_transaction_date&.prev_day ].compact.min || Date.current
    end
end
