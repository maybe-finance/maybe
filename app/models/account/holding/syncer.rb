class Account::Holding::Syncer
  def initialize(account, strategy:)
    @account = account
    @strategy = strategy
    @securities_cache = {}
  end

  def sync_holdings
    Rails.logger.tagged("Account::Holding::Syncer") do
      calculate_holdings
      persist_holdings
      purge_stale_holdings unless strategy == :reverse
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
        account.holdings.delete_all
      else
        account.holdings.delete_by("date < ? OR security_id NOT IN (?)", account.start_date, portfolio_security_ids)
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
