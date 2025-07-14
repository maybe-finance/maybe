class Balance::ReverseCalculator < Balance::BaseCalculator
  def calculate
    Rails.logger.tagged("Balance::ReverseCalculator") do
      current_balance = account.current_anchor_balance
      current_holdings_value = holdings_value_for_date(account.current_anchor_date)

      current_balance_components = balance_transformer.apply_valuation(
        OpenStruct.new(amount: current_balance),
        non_cash_valuation: current_holdings_value
      )

      previous_balance_components = nil

      balances = []

      account.current_anchor_date.downto(account.opening_anchor_date).map do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation_entry = sync_cache.get_valuation(date)

        # Reverse syncs ignore valuations *except* the current and opening anchors. See the test suite for an explanation of why we do this.
        if valuation_entry.present? && valuation_entry.valuation.opening_anchor?
          # Opening anchor valuation sets the total balance
          previous_balance_components = balance_transformer.apply_valuation(
            OpenStruct.new(amount: valuation_entry.amount),
            non_cash_valuation: holdings_value
          )
        else
          # Apply transactions in reverse
          # For mixed accounts, use holdings value as non-cash balance
          non_cash_balance = if account.accountable_type.in?([ "Investment", "Crypto" ])
            holdings_value
          else
            current_balance_components.non_cash_balance
          end

          previous_balance_components = balance_transformer.transform(
            cash_balance: current_balance_components.cash_balance,
            non_cash_balance: non_cash_balance,
            entries: entries
          )
        end

        # Build the balance for this date
        if valuation_entry.present? && valuation_entry.valuation.opening_anchor?
          # For opening anchor, use the calculated previous values
          if account.accountable_type.in?([ "Investment", "Crypto" ])
            balances << build_balance(date, previous_balance_components.cash_balance, holdings_value)
          else
            balances << build_balance(date, previous_balance_components.cash_balance, previous_balance_components.non_cash_balance)
          end
        else
          # For all other dates, use current values
          if account.accountable_type.in?([ "Investment", "Crypto" ])
            balances << build_balance(date, current_balance_components.cash_balance, holdings_value)
          else
            balances << build_balance(date, current_balance_components.cash_balance, current_balance_components.non_cash_balance)
          end
        end

        current_balance_components = previous_balance_components
      end

      balances
    end
  end

  private
    def balance_transformer
      @balance_transformer ||= Balance::Transformer.new(account, transformation_direction: :reverse)
    end
end
