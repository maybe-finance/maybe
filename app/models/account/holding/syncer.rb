class Account::Holding::Syncer
  def initialize(account, strategy:)
    @account = account
    @strategy = strategy
    @securities_cache = {}
  end

  def sync_holdings
    calculate_holdings
    Rails.logger.info("Persisting #{@holdings.size} holdings")
    persist_holdings

    unless strategy == :reverse
      purge_stale_holdings
    end

    @holdings
  end

  private
    attr_reader :account, :securities_cache, :strategy

    def calculate_holdings
      @holdings = calculator.calculate
    end

    def persist_holdings
      current_time = Time.now

      account.holdings.upsert_all(
        @holdings.map { |h| h.attributes
               .slice("date", "currency", "qty", "price", "amount", "security_id")
               .merge("updated_at" => current_time) },
        unique_by: %i[account_id security_id date currency]
      )
    end

    def purge_stale_holdings
      portfolio_security_ids = account.entries.account_trades.map { |entry| entry.entryable.security_id }.uniq

      # If there are no securities in the portfolio, delete all holdings
      if portfolio_security_ids.empty?
        Rails.logger.info("Clearing all holdings (no securities)")
        account.holdings.delete_all
      else
        deleted_count = account.holdings.delete_by("date < ? OR security_id NOT IN (?)", account.start_date, portfolio_security_ids)
        Rails.logger.info("Purged #{deleted_count} stale holdings") if deleted_count > 0
      end
    end

    def calculator
      if strategy == :reverse
        Account::Holding::ReverseCalculator.new(account)
      else
        Account::Holding::ForwardCalculator.new(account)
      end
    end
end
