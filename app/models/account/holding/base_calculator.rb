class Account::Holding::BaseCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    Rails.logger.tagged(self.class.name) do
      calculate_holdings
      Account::Holding.gapfill(@holdings)
    end
  end

  private
    def portfolio_cache
      @portfolio_cache ||= Account::Holding::PortfolioCache.new(account)
    end

    def empty_portfolio
      securities = portfolio_cache.get_securities
      securities.each_with_object({}) { |security, hash| hash[security.id] = 0 }
    end

    def generate_starting_portfolio
      empty_portfolio
    end

    def transform_portfolio(previous_portfolio, trade_entries, direction: :forward)
      new_quantities = previous_portfolio.dup

      trade_entries.each do |trade_entry|
        trade = trade_entry.entryable
        security_id = trade.security_id
        qty_change = trade.qty
        qty_change = qty_change * -1 if direction == :reverse
        new_quantities[security_id] = (new_quantities[security_id] || 0) + qty_change
      end

      new_quantities
    end

    def build_holdings(portfolio, date)
      Rails.logger.info "Generating holdings for #{portfolio.size} securities on #{date}"

      portfolio.map do |security_id, qty|
        price = portfolio_cache.get_price(security_id, date)

        account.holdings.build(
          security_id: security_id,
          date: date,
          qty: qty,
          price: price,
          currency: account.currency,
          amount: qty * price
        )
      end.compact
    end
end
