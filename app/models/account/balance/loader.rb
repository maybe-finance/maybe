class Account::Balance::Loader
  def initialize(account)
    @account = account
  end

  def load(balances, start_date)
    Account::Balance.transaction do
      upsert_balances!(balances)
      purge_stale_balances!(start_date)

      account.reload

      update_account_balance!(balances)
    end
  end

  private
    attr_reader :account

    def update_account_balance!(balances)
      last_balance = balances.select { |db| db.currency == account.currency }.last&.balance

      if account.plaid_account.present?
        account.update! balance: account.plaid_account.current_balance || last_balance
      else
        account.update! balance: last_balance if last_balance.present?
      end
    end

    def upsert_balances!(balances)
      current_time = Time.now
      balances_to_upsert = balances.map do |balance|
        balance.attributes.slice("date", "balance", "currency").merge("updated_at" => current_time)
      end

      account.balances.upsert_all(balances_to_upsert, unique_by: %i[account_id date currency])
    end

    def purge_stale_balances!(start_date)
      account.balances.delete_by("date < ?", start_date)
    end
end
