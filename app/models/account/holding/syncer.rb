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
      all_trade_entries = account.entries
                                 .account_trades
                                 .includes(entryable: :security)
                                 .where("date >= ?", sync_start_date)
                                 .order(:date)
      holdings = []
      portfolio = get_prior_portfolio

      (sync_start_date..Date.current).each do |date|
        trade_entries = all_trade_entries.select { |trade| trade.date == date }

        trade_entries.each do |entry|
          trade = entry.account_trade
          prior_qty = portfolio.dig(trade.security.isin, :qty) || 0
          new_qty = prior_qty + trade.qty

          portfolio[trade.security.isin] = {
            qty: new_qty,
            price: trade.price,
            amount: new_qty * trade.price,
            security_id: trade.security_id
          }
        end

        portfolio.each do |isin, holding|
          price = Security::Price.find_by!(date: date, isin: isin).price

          holding = account.holdings.build \
            date: date,
            security_id: holding[:security_id],
            qty: holding[:qty],
            price: price,
            amount: price * holding[:qty]

          holdings << holding
        end
      end

      holdings
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

    def get_prior_portfolio
      portfolio = {}
      prior_day_holdings = account.holdings.where(date: sync_start_date - 1.day)

      if prior_day_holdings.any?
        prior_day_holdings.each do |holding|
          portfolio[holding.security.isin] = {
            qty: holding.qty,
            price: holding.price,
            amount: holding.amount,
            security_id: holding.security_id
          }
        end
      end

      portfolio
    end

    def calculate_sync_start_date(start_date)
      start_date || account.entries.account_trades.order(:date).first.try(:date) || Date.current
    end
end
