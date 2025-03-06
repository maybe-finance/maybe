class Account::Holding::ForwardCalculator < Account::Holding::Calculator
  def calculate
    Rails.logger.tagged("Account::HoldingCalculator") do
      @securities_cache = {}
      preload_securities

      Rails.logger.info("Calculating holdings with strategy: forward sync")
      calculated_holdings = calculate_holdings

      gapfill_holdings(calculated_holdings)
    end
  end

  private
    def calculate_holdings
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
      Rails.logger.info "Generating holdings for #{portfolio.size} securities on #{date}"

      portfolio.map do |security_id, qty|
        security = securities_cache[security_id]

        price = security.dig(:prices)&.find { |p| p.date == date }

        # We prefer to use prices from our data provider.  But if the provider doesn't have an EOD price
        # for this security, we search through the account's trades and use the "spot" price at the time of
        # the most recent trade for that day's holding.  This is not as accurate, but it allows users to define
        # what we call "offline" securities (which is essential given we cannot get prices for all securities globally)
        if price.blank?
          converted_price = most_recent_trade_price(security_id, date)
        else
          converted_price = Money.new(price.price, price.currency).exchange_to(account.currency, fallback_rate: 1).amount
        end

        account.holdings.build(
          security: security.dig(:security),
          date: date,
          qty: qty,
          price: converted_price,
          currency: account.currency,
          amount: qty * converted_price
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
      @trades ||= account.entries.includes(entryable: :security).account_trades.chronological.to_a
    end

    def portfolio_start_date
      trades.first ? trades.first.date - 1.day : Date.current
    end

    def preload_securities
      # Get securities from trades and current holdings
      securities = trades.map(&:entryable).map(&:security).uniq
      securities += account.holdings.where(date: Date.current).map(&:security)
      securities.uniq!

      Rails.logger.info "Preloading #{securities.size} securities for account #{account.id}"

      securities.each do |security|
        Rails.logger.info "Loading security: ID=#{security.id} Ticker=#{security.ticker}"

        prices = Security::Price.find_prices(
          security: security,
          start_date: portfolio_start_date,
          end_date: Date.current
        )

        Rails.logger.info "Found #{prices.size} prices for security #{security.id}"

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

      account.holdings.where(date: Date.current, currency: account.currency).map do |holding|
        holding_quantities[holding.security_id] = holding.qty
      end

      holding_quantities
    end

    def most_recent_trade_price(security_id, date)
      first_trade = trades.select { |t| t.entryable.security_id == security_id }.min_by(&:date)
      most_recent_trade = trades.select { |t| t.entryable.security_id == security_id && t.date <= date }.max_by(&:date)

      if most_recent_trade
        most_recent_trade.entryable.price
      else
        first_trade.entryable.price
      end
    end
end
