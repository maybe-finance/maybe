class Holding::ReverseCalculator < Holding::BaseCalculator
  private
    # Reverse calculators will use the existing holdings as a source of security ids and prices
    # since it is common for a provider to supply "current day" holdings but not all the historical
    # trades that make up those holdings.
    def portfolio_cache
      @portfolio_cache ||= Holding::PortfolioCache.new(account, use_holdings: true)
    end

    def calculate_holdings
      current_portfolio = generate_starting_portfolio
      previous_portfolio = {}

      holdings = []

      Date.current.downto(account.start_date).each do |date|
        today_trades = portfolio_cache.get_trades(date: date)
        previous_portfolio = transform_portfolio(current_portfolio, today_trades, direction: :reverse)
        holdings += build_holdings(current_portfolio, date)
        current_portfolio = previous_portfolio
      end

      holdings
    end

    # Since this is a reverse sync, we start with today's holdings
    def generate_starting_portfolio
      holding_quantities = empty_portfolio

      todays_holdings = account.holdings.where(date: Date.current)

      todays_holdings.each do |holding|
        holding_quantities[holding.security_id] = holding.qty
      end

      holding_quantities
    end
end
