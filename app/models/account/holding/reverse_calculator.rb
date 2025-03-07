class Account::Holding::ReverseCalculator
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def calculate
    Rails.logger.tagged("Account::HoldingCalculator") do
      Rails.logger.info("Calculating holdings with strategy: reverse sync")
      calculated_holdings = calculate_holdings

      Account::Holding.gapfill(calculated_holdings)
    end
  end

  private
    def portfolio_cache
      @portfolio_cache ||= Account::Holding::PortfolioCache.new(account)
    end

    def calculate_holdings
      current_holding_quantities = load_current_holding_quantities
      prior_holding_quantities = {}

      holdings = []

      Date.current.downto(account.start_date).map do |date|
        today_trades = portfolio_cache.get_trades(date: date)
        prior_holding_quantities = calculate_portfolio(current_holding_quantities, today_trades)
        holdings += generate_holding_records(current_holding_quantities, date)
        current_holding_quantities = prior_holding_quantities
      end

      holdings
    end

    def generate_holding_records(portfolio, date)
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

    def calculate_portfolio(holding_quantities, today_trades, inverse: false)
      new_quantities = holding_quantities.dup

      today_trades.each do |trade|
        security_id = trade.entryable.security_id
        qty_change = inverse ? trade.entryable.qty : -trade.entryable.qty
        new_quantities[security_id] = (new_quantities[security_id] || 0) + qty_change
      end

      new_quantities
    end

    def load_empty_holding_quantities
      holding_quantities = {}

      trades = portfolio_cache.get_trades

      trades.map { |t| t.entryable.security_id }.uniq.each do |security_id|
        holding_quantities[security_id] = 0
      end

      holding_quantities
    end

    def load_current_holding_quantities
      holding_quantities = load_empty_holding_quantities

      account.holdings.where(date: Date.current, currency: account.currency).map do |holding|
        holding_quantities[holding.security_id] = holding.qty
      end

      holding_quantities
    end
end
