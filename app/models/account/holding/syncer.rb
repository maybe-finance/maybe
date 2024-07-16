class Account::Holding::Syncer
  attr_reader :warnings

  def initialize(account, start_date: nil)
    @account = account
    @warnings = []
    @sync_date_range = calculate_sync_start_date(start_date)..Date.current
    @portfolio = {}

    load_prior_portfolio if start_date
  end

  def run
    holdings = []

    sync_date_range.each do |date|
      holdings += build_holdings_for_date(date)
    end

    upsert_holdings holdings
  end

  private

    attr_reader :account, :sync_date_range

    def sync_entries
      @sync_entries ||= account.entries
                               .account_trades
                               .includes(entryable: :security)
                               .where("date >= ?", sync_date_range.begin)
                               .order(:date)
    end

    def build_holdings_for_date(date)
      trades = sync_entries.select { |trade| trade.date == date }

      @portfolio = generate_next_portfolio(@portfolio, trades)

      @portfolio.map do |isin, holding|
        price = Security::Price.find_by!(date: date, isin: isin).price

        account.holdings.build \
          date: date,
          security_id: holding[:security_id],
          qty: holding[:qty],
          price: price,
          amount: price * holding[:qty]
      end
    end

    def generate_next_portfolio(prior_portfolio, trade_entries)
      trade_entries.each_with_object(prior_portfolio) do |entry, new_portfolio|
        trade = entry.account_trade

        price = trade.price
        prior_qty = prior_portfolio.dig(trade.security.isin, :qty) || 0
        new_qty = prior_qty + trade.qty

        new_portfolio[trade.security.isin] = {
          qty: new_qty,
          price: price,
          amount: new_qty * price,
          security_id: trade.security_id
        }
      end
    end

    def upsert_holdings(holdings)
      current_time = Time.now
      holdings_to_upsert = holdings.map do |holding|
        holding.attributes
               .slice("date", "currency", "qty", "price", "amount", "security_id")
               .merge("updated_at" => current_time)
      end

      account.holdings.upsert_all(holdings_to_upsert, unique_by: %i[account_id security_id date currency])
    end

    def load_prior_portfolio
      prior_day_holdings = account.holdings.where(date: sync_date_range.begin - 1.day)

      prior_day_holdings.each do |holding|
        @portfolio[holding.security.isin] = {
          qty: holding.qty,
          price: holding.price,
          amount: holding.amount,
          security_id: holding.security_id
        }
      end
    end

    def calculate_sync_start_date(start_date)
      start_date || account.entries.account_trades.order(:date).first.try(:date) || Date.current
    end
end
