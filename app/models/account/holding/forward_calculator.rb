class Account::Holding::ForwardCalculator < Account::Holding::BaseCalculator
  private
    def calculate_holdings
      todays_portfolio = generate_starting_portfolio
      tomorrows_portfolio = {}
      @holdings = []

      account.start_date.upto(Date.current).each do |date|
        trades = portfolio_cache.get_trades(date: date)
        tomorrows_portfolio = transform_portfolio(todays_portfolio, trades, direction: :forward)
        @holdings += build_holdings(tomorrows_portfolio, date)
        todays_portfolio = tomorrows_portfolio
      end
    end
end
