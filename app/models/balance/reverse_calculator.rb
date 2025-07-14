class Balance::ReverseCalculator < Balance::BaseCalculator
  def calculate
    Rails.logger.tagged("Balance::ReverseCalculator") do
      today_balance = account.current_anchor_balance
      today_holdings_value = holdings_value_for_date(account.current_anchor_date)

      today_balance_components = balance_transformer.set_absolute_balance(
        total_balance: today_balance,
        holdings_value: today_holdings_value
      )

      yesterday_balance_components = nil

      # Calculates in reverse-chronological order
      account.current_anchor_date.downto(account.opening_anchor_date).map do |date|
        entries = sync_cache.get_entries(date)
        holdings_value = holdings_value_for_date(date)

        # Reverse syncs ignore valuations *except* the current and opening anchors. See the test suite for an explanation of why we do this.
        if account.has_opening_anchor? && date == account.opening_anchor_date
          # Opening anchor valuation sets the total balance
          today_balance_components = balance_transformer.set_absolute_balance(
            total_balance: account.opening_anchor_balance,
            holdings_value: holdings_value
          )

          build_balance(date, today_balance_components.cash_balance, today_balance_components.non_cash_balance)
        else
          # Apply transactions in reverse
          # For mixed accounts, use holdings value as non-cash balance
          non_cash_balance = if account.balance_type == :investment
            holdings_value
          else
            today_balance_components.non_cash_balance
          end

          yesterday_balance_components = balance_transformer.transform_balance(
            start_cash_balance: today_balance_components.cash_balance,
            start_non_cash_balance: today_balance_components.non_cash_balance,
            today_entries: entries,
            today_holdings_value: holdings_value
          )

          balance = build_balance(date, today_balance_components.cash_balance, non_cash_balance)

          today_balance_components = yesterday_balance_components

          balance
        end
      end
    end
  end

  private
    def balance_transformer
      @balance_transformer ||= Balance::Transformer.new(account, transformation_direction: :reverse)
    end
end
