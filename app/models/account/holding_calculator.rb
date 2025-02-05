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
      Rails.logger.info "[HoldingCalculator] Generating holdings for #{portfolio.size} securities on #{date}"

      portfolio.map do |security_id, qty|
        security = securities_cache[security_id]

        if security.blank?
          Rails.logger.error "[HoldingCalculator] Security #{security_id} not found in cache for account #{account.id}"
          next
        end

        price = security.dig(:prices)&.find { |p| p.date == date }

        if price.blank?
          Rails.logger.info "[HoldingCalculator] No price found for security #{security_id} on #{date}"
          next
        end

        converted_price = Money.new(price.price, price.currency).exchange_to(account.currency, fallback_rate: 1).amount

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

      Rails.logger.info "[HoldingCalculator] Preloading #{securities.size} securities for account #{account.id}"

      securities.each do |security|
        begin
          Rails.logger.info "[HoldingCalculator] Loading security: ID=#{security.id} Ticker=#{security.ticker}"

          prices = Security::Price.find_prices(
            security: security,
            start_date: portfolio_start_date,
            end_date: Date.current
          )

          Rails.logger.info "[HoldingCalculator] Found #{prices.size} prices for security #{security.id}"

          @securities_cache[security.id] = {
            security: security,
            prices: prices
          }
        rescue => e
          Rails.logger.error "[HoldingCalculator] Error processing security #{security.id}: #{e.message}"
          Rails.logger.error "[HoldingCalculator] Security details: #{security.attributes}"
          Rails.logger.error e.backtrace.join("\n")
          next # Skip this security and continue with others
        end
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
end
