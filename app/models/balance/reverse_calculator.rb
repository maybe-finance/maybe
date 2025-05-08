class Balance::ReverseCalculator < Balance::BaseCalculator
  private
    def calculate_balances
      current_cash_balance = account.cash_balance
      previous_cash_balance = nil

      @balances = []

      Date.current.downto(account.start_date).map do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation = sync_cache.get_valuation(date)

        previous_cash_balance = if valuation
          valuation.amount - holdings_value
        else
          calculate_next_balance(current_cash_balance, entries, direction: :reverse)
        end

        if valuation.present?
          @balances << build_balance(date, previous_cash_balance, holdings_value)
        else
          # If date is today, we don't distinguish cash vs. total since provider's are inconsistent with treatment
          # of the cash component.  Instead, just set the balance equal to the "total value" reported by the provider
          if date == Date.current
            @balances << build_balance(date, account.balance, 0)
          else
            @balances << build_balance(date, current_cash_balance, holdings_value)
          end
        end

        current_cash_balance = previous_cash_balance
      end

      @balances
    end
end
