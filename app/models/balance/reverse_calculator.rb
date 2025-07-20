class Balance::ReverseCalculator < Balance::BaseCalculator
  def calculate
    Rails.logger.tagged("Balance::ReverseCalculator") do
      # Since it's a reverse sync, we're starting with the "end of day" balance components and
      # calculating backwards to derive the "start of day" balance components.
      end_cash_balance = derive_cash_balance_on_date_from_total(
        total_balance: account.current_anchor_balance,
        date: account.current_anchor_date
      )
      end_non_cash_balance = account.current_anchor_balance - end_cash_balance

      # Calculates in reverse-chronological order (End of day -> Start of day)
      account.current_anchor_date.downto(account.opening_anchor_date).map do |date|
        if use_opening_anchor_for_date?(date)
          end_cash_balance = derive_cash_balance_on_date_from_total(
            total_balance: account.opening_anchor_balance,
            date: date
          )
          end_non_cash_balance = account.opening_anchor_balance - end_cash_balance

          start_cash_balance = end_cash_balance
          start_non_cash_balance = end_non_cash_balance

          build_balance(
            date: date,
            cash_balance: end_cash_balance,
            non_cash_balance: end_non_cash_balance
          )
        else
          start_cash_balance = derive_start_cash_balance(end_cash_balance: end_cash_balance, date: date)
          start_non_cash_balance = derive_start_non_cash_balance(end_non_cash_balance: end_non_cash_balance, date: date)

          # Even though we've just calculated "start" balances, we set today equal to end of day, then use those
          # in our next iteration (slightly confusing, but just the nature of a "reverse" sync)
          output_balance = build_balance(
            date: date,
            cash_balance: end_cash_balance,
            non_cash_balance: end_non_cash_balance
          )

          end_cash_balance = start_cash_balance
          end_non_cash_balance = start_non_cash_balance

          output_balance
        end
      end
    end
  end

  private

    # Negative entries amount on an "asset" account means, "account value has increased"
    # Negative entries amount on a "liability" account means, "account debt has decreased"
    # Positive entries amount on an "asset" account means, "account value has decreased"
    # Positive entries amount on a "liability" account means, "account debt has increased"
    def signed_entry_flows(entries)
      entry_flows = entries.sum(&:amount)
      account.asset? ? entry_flows : -entry_flows
    end

    # Reverse syncs are a bit different than forward syncs because we do not allow "reconciliation" valuations
    # to be used at all. This is primarily to keep the code and the UI easy to understand. For a more detailed
    # explanation, see the test suite.
    def use_opening_anchor_for_date?(date)
      account.has_opening_anchor? && date == account.opening_anchor_date
    end

    # Alias method, for algorithmic clarity
    # Derives cash balance, starting from the end-of-day, applying entries in reverse to get the start-of-day balance
    def derive_start_cash_balance(end_cash_balance:, date:)
      derive_cash_balance(end_cash_balance, date)
    end

    # Alias method, for algorithmic clarity
    # Derives non-cash balance, starting from the end-of-day, applying entries in reverse to get the start-of-day balance
    def derive_start_non_cash_balance(end_non_cash_balance:, date:)
      derive_non_cash_balance(end_non_cash_balance, date, direction: :reverse)
    end
end
