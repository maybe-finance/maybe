class Account::Holding::Syncer
  attr_reader :warnings

  def initialize(account, start_date: nil)
    @account = account
    @warnings = []
    @sync_start_date = calculate_sync_start_date(start_date)
  end

  def run
    daily_holdings = calculate_daily_holdings

    Account::Holding.transaction do
      upsert_holdings! daily_holdings
    end
  end

  private

    attr_reader :account, :sync_start_date

    def calculate_daily_holdings
      trades = account.entries.account_trades.where("date >= ?", sync_start_date).to_a

      [] if trades.empty?
    end

    def upsert_holdings!(holdings)
      current_time = Time.now
      holdings_to_upsert = holdings.map do |holding|
        holding.attributes
               .slice("date", "currency", "qty", "price", "amount", "security_id")
               .merge("updated_at" => current_time)
      end

      account.holdings.upsert_all(holdings_to_upsert, unique_by: %i[account_id security_id date currency])
    end

    def calculate_sync_start_date(start_date)
      start_date
    end
end
