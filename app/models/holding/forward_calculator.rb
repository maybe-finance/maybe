class Holding::ForwardCalculator < Holding::BaseCalculator
  private
    def portfolio_cache
      @portfolio_cache ||= Holding::PortfolioCache.new(account)
    end

    def calculate_holdings
      current_portfolio = generate_starting_portfolio
      next_portfolio = {}
      holdings = []

      account.start_date.upto(Date.current).each do |date|
        trades = portfolio_cache.get_trades(date: date)
        next_portfolio = transform_portfolio(current_portfolio, trades, direction: :forward)
        holdings += build_holdings(next_portfolio, date)
        current_portfolio = next_portfolio
      end

      holdings
    end
end
