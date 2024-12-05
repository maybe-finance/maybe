class Account::ReversePortfolioCalculator
  def initialize(account)
    @account = account
  end

  def calculate 
    return [] if account.holdings.empty?
    return account.holdings if account.trades.empty?

    trades = account.entries.includes(:entryable).account_trades.to_a

    current_holding_quantities = load_current_holding_quantities
    prior_holding_quantities = {} 

    holdings = []

    Date.current.downto(trades.first&.date || Date.current).map do |date|
      today_trades = trades.select { |t| t.date == date }

      prior_holding_quantities = calculate_prior_quantities(current_holding_quantities, today_trades)

      current_holding_quantities.map do |security_id, qty|
        security = Security.find(security_id)
        price = Security::Price.find_price(security:, date:)

        holdings << Account::Holding.new(
          security: security,
          date: date,
          qty: qty,
          price: price.price,
          currency: price.currency,
          amount: qty * price.price
        )
      end

      current_holding_quantities = prior_holding_quantities
    end 

    holdings
  end

  private 
    attr_reader :account

    def calculate_prior_quantities(current_holding_quantities, today_trades)
      prior_quantities = current_holding_quantities.dup

      today_trades.each do |trade|
        security_id = trade.entryable.security_id
        prior_quantities[security_id] = (prior_quantities[security_id] || 0) - trade.entryable.qty
      end

      prior_quantities
    end

    def load_current_holding_quantities
      holding_quantities = {}

      account.holdings.where(date: Date.current).map do |holding|
        holding_quantities[holding.security_id] = holding.qty
      end

      holding_quantities
    end
end
