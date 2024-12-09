class Account::HoldingCalculator
  def initialize(account)
    @account = account
  end

  def trades
    account.entries.includes(:entryable).account_trades.to_a
  end

  def portfolio_start_date
    trades.first ? trades.first.date - 1.day : Date.current
  end

  def calculate(reverse: false)
    calculated_holdings = reverse ? reverse_holdings : forward_holdings
    gapfill_holdings(calculated_holdings)
  end

  def reverse_holdings
    current_holding_quantities = load_current_holding_quantities
    prior_holding_quantities = {}

    holdings = []

    Date.current.downto(portfolio_start_date).map do |date|
      today_trades = trades.select { |t| t.date == date }

      prior_holding_quantities = calculate_quantities(current_holding_quantities, today_trades)

      current_holding_quantities.map do |security_id, qty|
        security = Security.find(security_id)
        price = Security::Price.find_price(security:, date:)

        holdings << account.holdings.build(
          security: security,
          date: date,
          qty: qty,
          price: price.price,
          currency: price.currency,
          amount: qty * price.price
        ) if price.present?
      end

      current_holding_quantities = prior_holding_quantities
    end

    holdings
  end

  def forward_holdings
    prior_holding_quantities = load_empty_holding_quantities
    current_holding_quantities = {}

    holdings = []

    portfolio_start_date.upto(Date.current).map do |date|
      today_trades = trades.select { |t| t.date == date }

      current_holding_quantities = calculate_quantities(prior_holding_quantities, today_trades, inverse: true)

      current_holding_quantities.map do |security_id, qty|
        security = Security.find(security_id)
        price = Security::Price.find_price(security:, date:)

        holdings << account.holdings.build(
          security: security,
          date: date,
          qty: qty,
          price: price.price,
          currency: price.currency,
          amount: qty * price.price
        ) if price.present?
      end

      prior_holding_quantities = current_holding_quantities
    end

    holdings
  end

  def gapfill_holdings(holdings)
    filled_holdings = []

    holdings.group_by { |h| h.security_id }.each do |security_id, security_holdings|
      # Skip if no holdings exist for this security
      next if security_holdings.empty?

      sorted = security_holdings.sort_by(&:date)
      previous_holding = sorted.first

      sorted.first.date.upto(Date.current) do |date|
        holding = security_holdings.find { |h| h.date == date }

        if holding
          filled_holdings << holding
          previous_holding = holding
        else
          # Create a new holding based on the previous day's data
          filled_holdings << account.holdings.build(
            security: previous_holding.security,
            date: date,
            qty: previous_holding.qty,
            price: previous_holding.price,
            currency: previous_holding.currency,
            amount: previous_holding.amount
          )
        end
      end
    end

    filled_holdings
  end

  private
    attr_reader :account

    def calculate_quantities(holding_quantities, today_trades, inverse: false)
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

      trades.map { |t| t.entryable.security_id }.uniq.each do |security_id|
        holding_quantities[security_id] = 0
      end

      holding_quantities
    end

    def load_current_holding_quantities
      holding_quantities = {}

      trades.map { |t| t.entryable.security_id }.uniq.each do |security_id|
        holding_quantities[security_id] = 0
      end

      account.holdings.where(date: Date.current).map do |holding|
        holding_quantities[holding.security_id] = holding.qty
      end

      holding_quantities
    end
end
