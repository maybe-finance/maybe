class Balance::ForwardCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    Rails.logger.tagged("Balance::ForwardCalculator") do
      calculate_balances
    end
  end

  private
    def calculate_balances
      current_cash_balance = account.opening_cash_balance
      next_cash_balance = nil

      @balances = []

      end_date = [ account.entries.order(:date).last&.date, account.holdings.order(:date).last&.date ].compact.max || Date.current

      account.opening_date.upto(end_date).each do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation = sync_cache.get_reconciliation_valuation(date)

        next_cash_balance = if valuation
          valuation.amount - holdings_value
        else
          calculate_next_balance(current_cash_balance, entries, direction: :forward)
        end

        @balances << build_balance(date, next_cash_balance, holdings_value)

        current_cash_balance = next_cash_balance
      end

      @balances
    end

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
