class Account::Balance::ForwardCalculator < Account::Balance::BaseCalculator
  private
    def calculate_balances
      prior_cash_balance = 0
      current_cash_balance = nil

      @balances = []

      account.start_date.upto(Date.current).each do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation = sync_cache.get_valuation(date)

        current_cash_balance = if valuation
          # Since a valuation means "total balance" (which includes holdings), we back out holdings value to get cash balance
          valuation.amount - holdings_value
        else
          calculate_next_balance(prior_cash_balance, entries, direction: :forward)
        end

        @balances << build_balance(date, current_cash_balance, holdings_value)

        prior_cash_balance = current_cash_balance
      end

      @balances
    end
end
