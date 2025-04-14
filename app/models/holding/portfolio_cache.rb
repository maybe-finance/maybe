class Holding::PortfolioCache
  attr_reader :account, :use_holdings

  class SecurityNotFound < StandardError
    def initialize(security_id, account_id)
      super("Security id=#{security_id} not found in portfolio cache for account #{account_id}.  This should not happen unless securities were preloaded incorrectly.")
    end
  end

  def initialize(account, use_holdings: false)
    @account = account
    @use_holdings = use_holdings
    load_prices
  end

  def get_trades(date: nil)
    if date.blank?
      trades
    else
      trades.select { |t| t.date == date }
    end
  end

  def get_price(security_id, date)
    security = @security_cache[security_id]
    raise SecurityNotFound.new(security_id, account.id) unless security

    price = security[:prices].select { |p| p.price.date == date }.min_by(&:priority)&.price

    return nil unless price

    price_money = Money.new(price.price, price.currency)

    converted_amount = price_money.exchange_to(account.currency, fallback_rate: 1).amount

    Security::Price.new(
      security_id: security_id,
      date: price.date,
      price: converted_amount,
      currency: account.currency
    )
  end

  def get_securities
    @security_cache.map { |_, v| v[:security] }
  end

  private
    PriceWithPriority = Data.define(:price, :priority)

    def trades
      @trades ||= account.entries.includes(entryable: :security).trades.chronological.to_a
    end

    def holdings
      @holdings ||= account.holdings.chronological.to_a
    end

    def collect_unique_securities
      unique_securities_from_trades = trades.map(&:entryable).map(&:security).uniq

      return unique_securities_from_trades unless use_holdings

      unique_securities_from_holdings = holdings.map(&:security).uniq

      (unique_securities_from_trades + unique_securities_from_holdings).uniq
    end

    # Loads all known prices for all securities in the account with priority based on source:
    # 1 - DB or provider prices
    # 2 - Trade prices
    # 3 - Holding prices
    def load_prices
      @security_cache = {}
      securities = collect_unique_securities

      Rails.logger.info "Preloading #{securities.size} securities for account #{account.id}"

      securities.each do |security|
        Rails.logger.info "Loading security: ID=#{security.id} Ticker=#{security.ticker}"

        # Load prices from provider to DB
        security.sync_provider_prices(start_date: account.start_date)

        # High priority prices from DB (synced from provider)
        db_prices = security.prices.where(date: account.start_date..Date.current).map do |price|
          PriceWithPriority.new(
            price: price,
            priority: 1
          )
        end

        # Medium priority prices from trades
        trade_prices = trades
          .select { |t| t.entryable.security_id == security.id }
          .map do |trade|
            PriceWithPriority.new(
              price: Security::Price.new(
                security: security,
                price: trade.entryable.price,
                currency: trade.entryable.currency,
                date: trade.date
              ),
              priority: 2
            )
          end

        # Low priority prices from holdings (if applicable)
        holding_prices = if use_holdings
          holdings.select { |h| h.security_id == security.id }.map do |holding|
            PriceWithPriority.new(
              price: Security::Price.new(
                security: security,
                price: holding.price,
                currency: holding.currency,
                date: holding.date
              ),
              priority: 3
            )
          end
        else
          []
        end

        @security_cache[security.id] = {
          security: security,
          prices: db_prices + trade_prices + holding_prices
        }
      end
    end
end
