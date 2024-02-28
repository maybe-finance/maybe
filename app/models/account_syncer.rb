class AccountSyncer
    def initialize(account)
      @account = account
    end

    def sync
        sync_balances
        purge_balances

        Rails.logger.info("Synced account #{@account.name}")
    end

    private
        # TODO: Support partial syncs via start_date
        def sync_balances(start_date = nil)
          sync_start_date = [ start_date, @account.effective_start_date ].compact.max

          valuations = @account.valuations.where("date >= ?", sync_start_date).order(:date).select(:date, :value)
          transactions = @account.transactions.where("date > ?", sync_start_date).order(:date).select(:date, :amount)
          oldest_entry = [ valuations.first, transactions.first ].compact.min_by(&:date)

          net_transaction_flows = transactions.sum(&:amount)
          implied_start_balance = oldest_entry.is_a?(Valuation) ? oldest_entry.value : @account.balance + net_transaction_flows

          prior_balance = implied_start_balance
          calculated_balances = ((sync_start_date + 1.day)..Date.current).map do |date|
            valuation = valuations.find { |v| v.date == date }

            if valuation
                current_balance = valuation.value
            else
                current_day_net_transaction_flows = transactions.select { |t| t.date == date }.sum(&:amount)
                current_balance = prior_balance - current_day_net_transaction_flows
            end

            prior_balance = current_balance

            { date: date, balance: current_balance, updated_at: Time.current }
          end

          balances_to_upsert = [
            { date: sync_start_date, balance: implied_start_balance, updated_at: Time.current },
            *calculated_balances
          ]

          @account.balances.upsert_all(balances_to_upsert, unique_by: :index_account_balances_on_account_id_and_date)
        end

        def purge_balances
            @account.balances.where("date < ?", @account.effective_start_date).delete_all
        end
end
