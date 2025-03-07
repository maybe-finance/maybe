class Account::Holding::PortfolioCache
  attr_reader :account

  class SecurityNotFound < StandardError
    def initialize(security_id, account_id)
      super("Security id=#{security_id} not found in portfolio cache for account #{account_id}.  This should not happen unless securities were preloaded incorrectly.")
    end
  end

  def initialize(account)
    @account = account
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

    price = security[:prices].find { |p| p.date == date }

    # We prefer to use prices from our data provider.  But if the provider doesn't have an EOD price
    # for this security, we search through the account's trades and use the "spot" price at the time of
    # the most recent trade for that day's holding.  This is not as accurate, but it allows users to define
    # what we call "offline" securities (which is essential given we cannot get prices for all securities globally)
    if price.blank?
      converted_price = most_recent_trade_price(security_id, date)
    else
      converted_price = Money.new(price.price, price.currency).exchange_to(account.currency, fallback_rate: 1).amount
    end

    converted_price
  end

  def get_securities
    @security_cache.map { |_, v| v[:security] }
  end

  private
    def trades
      @trades ||= account.entries.includes(entryable: :security).account_trades.chronological.to_a
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

    def load_prices
      @security_cache = {}

      # Get securities from trades and current holdings.  We need them from holdings
      # because for linked accounts, our provider gives us holding data that may not
      # exist solely in the trades history.
      securities = trades.map(&:entryable).map(&:security).uniq
      securities += account.holdings.where(date: Date.current).map(&:security)
      securities.uniq!

      Rails.logger.info "Preloading #{securities.size} securities for account #{account.id}"

      securities.each do |security|
        Rails.logger.info "Loading security: ID=#{security.id} Ticker=#{security.ticker}"

        fetched_prices = Security::Price.find_prices(
          security: security,
          start_date: account.start_date,
          end_date: Date.current
        )

        Rails.logger.info "Found #{fetched_prices.size} prices for security #{security.id}"

        @security_cache[security.id] = {
          security: security,
          prices: fetched_prices
        }
      end
    end
end
