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
      calculated_balance = @balances.sort_by(&:date).last&.balance || 0
      calculated_holdings_value = @holdings.select { |h| h.date == Date.current }.sum(&:amount) || 0
      calculated_cash_balance = calculated_balance - calculated_holdings_value

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
               .slice("date", "balance", "cash_balance", "currency")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id date currency]
      )
    end

    def purge_stale_balances
      deleted_count = account.balances.delete_by("date < ?", account.start_date)
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
