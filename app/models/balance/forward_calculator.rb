class Balance::ForwardCalculator < Balance::BaseCalculator
  def calculate
    Rails.logger.tagged("Balance::ForwardCalculator") do
      # Derive initial balances from opening anchor
      opening_balance = account.opening_anchor_balance
      opening_holdings_value = holdings_value_for_date(account.opening_anchor_date)

      current_balance_components = balance_transformer.apply_valuation(
        OpenStruct.new(amount: opening_balance),
        non_cash_valuation: opening_holdings_value
      )

      next_balance_components = nil

      balances = []

      calc_start_date.upto(calc_end_date).each do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation = sync_cache.get_reconciliation_valuation(date)

        if valuation
          # Reconciliation valuation sets the total balance
          next_balance_components = balance_transformer.apply_valuation(
            valuation,
            non_cash_valuation: holdings_value
          )
        else
          # Apply transactions
          # For mixed accounts, use holdings value as non-cash balance
          non_cash_balance = if account.accountable_type.in?([ "Investment", "Crypto" ])
            holdings_value
          else
            current_balance_components.non_cash_balance
          end

          next_balance_components = balance_transformer.transform(
            cash_balance: current_balance_components.cash_balance,
            non_cash_balance: non_cash_balance,
            entries: entries
          )
        end

        balances << build_balance(date, next_balance_components.cash_balance, next_balance_components.non_cash_balance)

        current_balance_components = next_balance_components
      end

      balances
    end
  end

  private
    def balance_transformer
      @balance_transformer ||= Balance::Transformer.new(account, transformation_direction: :forward)
    end

    def calc_start_date
      account.opening_anchor_date
    end

    def calc_end_date
      [ account.entries.order(:date).last&.date, account.holdings.order(:date).last&.date ].compact.max || Date.current
    end
end
