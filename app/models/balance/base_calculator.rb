class Balance::BaseCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    Rails.logger.tagged(self.class.name) do
      calculate_balances
    end
  end

  private
    def sync_cache
      @sync_cache ||= Balance::SyncCache.new(account)
    end

    def build_balance(date, cash_balance, holdings_value)
      Balance.new(
        account_id: account.id,
        date: date,
        balance: holdings_value + cash_balance,
        cash_balance: cash_balance,
        currency: account.currency
      )
    end

    def calculate_next_balance(prior_balance, transactions, direction: :forward)
      flows = transactions.sum(&:amount)
      negated = direction == :forward ? account.asset? : account.liability?
      flows *= -1 if negated
      prior_balance + flows
    end
end
