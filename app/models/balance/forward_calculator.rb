class Balance::ForwardCalculator < Balance::BaseCalculator
  private
    def calculate_balances
      current_cash_balance = 0
      next_cash_balance = nil

      @balances = []

      account.start_date.upto(Date.current).each do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation = sync_cache.get_valuation(date)

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
end
