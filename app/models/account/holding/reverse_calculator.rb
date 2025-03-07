class Account::Holding::ReverseCalculator < Account::Holding::BaseCalculator
  private
    def calculate_holdings
      todays_portfolio = generate_starting_portfolio
      yesterdays_portfolio = {}

      @holdings = []

      Date.current.downto(account.start_date).map do |date|
        today_trades = portfolio_cache.get_trades(date: date)
        yesterdays_portfolio = transform_portfolio(todays_portfolio, today_trades, direction: :reverse)
        @holdings += build_holdings(todays_portfolio, date)
        todays_portfolio = yesterdays_portfolio
      end
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
