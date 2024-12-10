class Account::HoldingCalculator
  def initialize(account)
    @account = account
    @securities_cache = {}
  end

  def calculate(reverse: false)
    preload_securities
    calculated_holdings = reverse ? reverse_holdings : forward_holdings
    gapfill_holdings(calculated_holdings)
  end

  private
    attr_reader :account, :securities_cache

    def reverse_holdings
      current_holding_quantities = load_current_holding_quantities
      prior_holding_quantities = {}

      holdings = []

      Date.current.downto(portfolio_start_date).map do |date|
        today_trades = trades.select { |t| t.date == date }
        prior_holding_quantities = calculate_portfolio(current_holding_quantities, today_trades)
        holdings += generate_holding_records(current_holding_quantities, date)
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
        current_holding_quantities = calculate_portfolio(prior_holding_quantities, today_trades, inverse: true)
        holdings += generate_holding_records(current_holding_quantities, date)
        prior_holding_quantities = current_holding_quantities
      end

      holdings
    end

    def generate_holding_records(portfolio, date)
      portfolio.map do |security_id, qty|
        security = securities_cache[security_id]
        price = security.dig(:prices)&.find { |p| p.date == date }

        next if price.blank?

        account.holdings.build(
          security: security.dig(:security),
          date: date,
          qty: qty,
          price: price.price,
          currency: price.currency,
          amount: qty * price.price
        )
      end.compact
    end

    def gapfill_holdings(holdings)
      filled_holdings = []

      holdings.group_by { |h| h.security_id }.each do |security_id, security_holdings|
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

    def trades
      @trades ||= account.entries.includes(entryable: :security).account_trades.to_a
    end

    def portfolio_start_date
      trades.first ? trades.first.date - 1.day : Date.current
    end

    def preload_securities
      securities = trades.map(&:entryable).map(&:security).uniq

      securities.each do |security|
        prices = Security::Price.find_prices(
          security: security,
          start_date: portfolio_start_date,
          end_date: Date.current
        )

        @securities_cache[security.id] = {
          security: security,
          prices: prices
        }
      end
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

      trades.map { |t| t.entryable.security_id }.uniq.each do |security_id|
        holding_quantities[security_id] = 0
      end

      holding_quantities
    end

    def load_current_holding_quantities
      holding_quantities = load_empty_holding_quantities

      account.holdings.where(date: Date.current).map do |holding|
        holding_quantities[holding.security_id] = holding.qty
      end

      holding_quantities
    end
end
