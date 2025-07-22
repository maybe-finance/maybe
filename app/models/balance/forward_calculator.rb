class Balance::ForwardCalculator < Balance::BaseCalculator
  def calculate
    Rails.logger.tagged("Balance::ForwardCalculator") do
      start_cash_balance = derive_cash_balance_on_date_from_total(
        total_balance: 0,
        date: account.opening_anchor_date
      )
      start_non_cash_balance = 0

      calc_start_date.upto(calc_end_date).map do |date|
        valuation = sync_cache.get_valuation(date)

        if valuation
          end_cash_balance = derive_cash_balance_on_date_from_total(
            total_balance: valuation.amount,
            date: date
          )
          end_non_cash_balance = valuation.amount - end_cash_balance
        else
          end_cash_balance = derive_end_cash_balance(start_cash_balance: start_cash_balance, date: date)
          end_non_cash_balance = derive_end_non_cash_balance(start_non_cash_balance: start_non_cash_balance, date: date)
        end

        flows = flows_for_date(date)
        market_value_change = market_value_change_on_date(date, flows)

        output_balance = build_balance(
          date: date,
          balance: end_cash_balance + end_non_cash_balance,
          cash_balance: end_cash_balance,
          start_cash_balance: start_cash_balance,
          start_non_cash_balance: start_non_cash_balance,
          cash_inflows: flows[:cash_inflows],
          cash_outflows: flows[:cash_outflows],
          non_cash_inflows: flows[:non_cash_inflows],
          non_cash_outflows: flows[:non_cash_outflows],
          cash_adjustments: cash_adjustments_for_date(start_cash_balance, flows[:cash_inflows] - flows[:cash_outflows], valuation),
          non_cash_adjustments: non_cash_adjustments_for_date(start_non_cash_balance, flows[:non_cash_inflows] - flows[:non_cash_outflows], valuation),
          net_market_flows: market_value_change
        )

        # Set values for the next iteration
        start_cash_balance = end_cash_balance
        start_non_cash_balance = end_non_cash_balance

        output_balance
      end
    end
  end

  private
    def calc_start_date
      account.opening_anchor_date
    end

    def calc_end_date
      [ account.entries.order(:date).last&.date, account.holdings.order(:date).last&.date ].compact.max || Date.current
    end

    # Negative entries amount on an "asset" account means, "account value has increased"
    # Negative entries amount on a "liability" account means, "account debt has decreased"
    # Positive entries amount on an "asset" account means, "account value has decreased"
    # Positive entries amount on a "liability" account means, "account debt has increased"
    def signed_entry_flows(entries)
      entry_flows = entries.sum(&:amount)
      account.asset? ? -entry_flows : entry_flows
    end

    # Derives cash balance, starting from the start-of-day, applying entries in forward to get the end-of-day balance
    def derive_end_cash_balance(start_cash_balance:, date:)
      derive_cash_balance(start_cash_balance, date)
    end

    # Derives non-cash balance, starting from the start-of-day, applying entries in forward to get the end-of-day balance
    def derive_end_non_cash_balance(start_non_cash_balance:, date:)
      derive_non_cash_balance(start_non_cash_balance, date, direction: :forward)
    end
end
