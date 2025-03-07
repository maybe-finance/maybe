class Account::Holding::ReverseCalculator < Account::Holding::BaseCalculator
  private
    def calculate_holdings
      current_portfolio = generate_starting_portfolio
      previous_portfolio = {}

      @holdings = []

      Date.current.downto(account.start_date).map do |date|
        today_trades = portfolio_cache.get_trades(date: date)
        previous_portfolio = transform_portfolio(current_portfolio, today_trades, direction: :reverse)
        @holdings += build_holdings(current_portfolio, date)
        current_portfolio = previous_portfolio
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
