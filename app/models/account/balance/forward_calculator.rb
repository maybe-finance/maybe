class Account::Balance::ForwardCalculator < Account::Balance::BaseCalculator
  def calculate
    Rails.logger.tagged("Account::BalanceCalculator") do
      calculate_cash_balances
      calculate_balances
    end
  end

  private
    def calculate_balances
      @balances = []

      @balances = @cash_balances.map do |balance|
        holdings = sync_cache.get_holdings(balance.date)
        holdings_value = holdings.sum(&:amount)
        build_balance(balance.balance + holdings_value, balance.date)
      end.compact
    end

    def calculate_cash_balances
      prior_cash_balance = 0
      current_cash_balance = nil

      @cash_balances = []

      account.start_date.upto(Date.current).each do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        valuation = sync_cache.get_valuation(date)

        current_cash_balance = if valuation
          # To get this to a cash valuation, we back out holdings value on day
          valuation.amount - holdings.sum(&:amount)
        else
          calculate_next_balance(prior_cash_balance, entries, direction: :forward)
        end

        @cash_balances << CashBalance.new(date, current_cash_balance)
        prior_cash_balance = current_cash_balance
      end
    end
end
