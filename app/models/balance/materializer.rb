class Balance::Materializer
  attr_reader :account, :strategy

  def initialize(account, strategy:)
    @account = account
    @strategy = strategy
  end

  def materialize_balances
    Balance.transaction do
      materialize_holdings
      calculate_balances

      Rails.logger.info("Persisting #{@balances.size} balances")
      persist_balances

      purge_stale_balances

      if strategy == :forward
        update_account_info
      end
    end
  end

  private
    def materialize_holdings
      @holdings = Holding::Materializer.new(account, strategy: strategy).materialize_holdings
    end

    def update_account_info
      # Query fresh balance from DB to get generated column values
      current_balance = account.balances
        .where(currency: account.currency)
        .order(date: :desc)
        .first

      if current_balance
        calculated_balance = current_balance.end_balance
        calculated_cash_balance = current_balance.end_cash_balance
      else
        # Fallback if no balance exists
        calculated_balance = 0
        calculated_cash_balance = 0
      end

      Rails.logger.info("Balance update: cash=#{calculated_cash_balance}, total=#{calculated_balance}")

      account.update!(
        balance: calculated_balance,
        cash_balance: calculated_cash_balance
      )
    end

    def calculate_balances
      @balances = calculator.calculate
    end

    def persist_balances
      current_time = Time.now
      account.balances.upsert_all(
        @balances.map { |b| b.attributes
               .slice("date", "balance", "cash_balance", "currency",
                      "start_cash_balance", "start_non_cash_balance",
                      "cash_inflows", "cash_outflows",
                      "non_cash_inflows", "non_cash_outflows",
                      "net_market_flows",
                      "cash_adjustments", "non_cash_adjustments",
                      "flows_factor")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id date currency]
      )
    end

    def purge_stale_balances
      sorted_balances = @balances.sort_by(&:date)
      oldest_calculated_balance_date = sorted_balances.first&.date
      newest_calculated_balance_date = sorted_balances.last&.date
      deleted_count = account.balances.delete_by("date < ? OR date > ?", oldest_calculated_balance_date, newest_calculated_balance_date)
      Rails.logger.info("Purged #{deleted_count} stale balances") if deleted_count > 0
    end

    def calculator
      if strategy == :reverse
        Balance::ReverseCalculator.new(account)
      else
        Balance::ForwardCalculator.new(account)
      end
    end
end
