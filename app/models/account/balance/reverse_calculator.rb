class Account::Balance::ReverseCalculator < Account::Balance::BaseCalculator
  private
    def calculate_balances
      todays_cash_balance = account.cash_balance
      yesterdays_cash_balance = nil

      @balances = []

      Date.current.downto(account.start_date).map do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation = sync_cache.get_valuation(date)

        yesterdays_cash_balance = if valuation
          # Since a valuation means "total balance" (which includes holdings), we back out holdings value to get cash balance
          valuation.amount - holdings_value
        else
          calculate_next_balance(todays_cash_balance, entries, direction: :reverse)
        end

        if valuation.present?
          @balances << build_balance(date, yesterdays_cash_balance, holdings_value)
        else
          @balances << build_balance(date, todays_cash_balance, holdings_value)
        end

        todays_cash_balance = yesterdays_cash_balance
      end

      @balances
    end
end
