class Balance::ForwardCalculator < Balance::BaseCalculator
  def calculate
    Rails.logger.tagged("Balance::ForwardCalculator") do
      current_balance_components = balance_transformer.set_absolute_balance(
        total_balance: account.opening_anchor_balance,
        # non_cash_balance: derive_non_cash_balance_for_date(account.opening_anchor_date, prior_non_cash_balance: nil),
        holdings_value: holdings_value_for_date(account.opening_anchor_date)
      )

      calc_start_date.upto(calc_end_date).map do |date|
        entries = sync_cache.get_entries(date)
        holdings_value = holdings_value_for_date(date)
        valuation = sync_cache.get_reconciliation_valuation(date)

        if valuation
          # Reconciliation valuation sets the total balance
          next_balance_components = balance_transformer.set_absolute_balance(
            total_balance: valuation.amount,
            holdings_value: holdings_value
          )
        else
          # Apply transactions
          # For mixed accounts, use holdings value as non-cash balance
          non_cash_balance = if account.accountable_type.in?([ "Investment", "Crypto" ])
            holdings_value
          else
            current_balance_components.non_cash_balance
          end

          next_balance_components = balance_transformer.transform_balance(
            start_cash_balance: current_balance_components.cash_balance,
            start_non_cash_balance: non_cash_balance,
            today_entries: entries,
            today_holdings_value: holdings_value
          )
        end

        current_balance_components = next_balance_components

        build_balance(date, next_balance_components.cash_balance, next_balance_components.non_cash_balance)
      end
    end
  end

  private
    def balance_transformer
      @balance_transformer ||= Balance::Transformer.new(account, transformation_direction: :forward)
    end

    def derive_non_cash_balance_for_date(date, prior_non_cash_balance:)
      if account.balance_type == :investment
        holdings_value_for_date(date)
      else
        prior_non_cash_balance
      end
    end

    def calc_start_date
      account.opening_anchor_date
    end

    def calc_end_date
      [ account.entries.order(:date).last&.date, account.holdings.order(:date).last&.date ].compact.max || Date.current
    end
end
