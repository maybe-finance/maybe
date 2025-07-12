class Balance::ReverseCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    Rails.logger.tagged("Balance::ReverseCalculator") do
      calculate_balances
    end
  end

  private
    def calculate_balances
      # TODO: This is a temporary implementation that relies on the account.cash_balance field.
      # In the future, we'll introduce HoldingValuation as an Entryable type that tracks
      # individual holdings values. The reverse calculator will then:
      # 1. Read HoldingValuations to get the holdings breakdown
      # 2. Use the current anchor Valuation for the total balance
      # 3. Derive cash balance as: total_balance - sum(holding_valuations)
      # This will give us a fully event-sourced approach without relying on cached/derived fields.
      current_cash_balance = account.current_anchor_balance - holdings_value_for_date(account.current_anchor_date)
      previous_cash_balance = nil

      @balances = []

      account.current_anchor_date.downto(account.opening_anchor_date).map do |date|
        entries = sync_cache.get_entries(date)
        holdings = sync_cache.get_holdings(date)
        holdings_value = holdings.sum(&:amount)
        valuation_entry = sync_cache.get_valuation(date)

        # Reverse syncs ignore valuations *except* the current and opening anchors. See the test suite for an explanation of why we do this.
        previous_cash_balance = if valuation_entry.present? && valuation_entry.valuation.opening_anchor?
          valuation_entry.amount - holdings_value
        else
          calculate_next_balance(current_cash_balance, entries, direction: :reverse)
        end

        if valuation_entry.present? && valuation_entry.valuation.opening_anchor?
          @balances << build_balance(date, previous_cash_balance, holdings_value)
        else
          @balances << build_balance(date, current_cash_balance, holdings_value)
        end

        current_cash_balance = previous_cash_balance
      end

      @balances
    end

    def sync_cache
      @sync_cache ||= Balance::SyncCache.new(account)
    end

    def build_balance(date, cash_balance, holdings_value)
      Balance.new(
        account_id: account.id,
        date: date,
        balance: holdings_value + cash_balance,
        cash_balance: cash_balance,
        currency: account.currency
      )
    end

    def holdings_value_for_date(date)
      holdings = sync_cache.get_holdings(date)
      holdings.sum(&:amount)
    end

    def calculate_next_balance(prior_balance, transactions, direction: :forward)
      flows = transactions.sum(&:amount)
      negated = direction == :forward ? account.asset? : account.liability?
      flows *= -1 if negated
      prior_balance + flows
    end
end
