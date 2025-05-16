class MarketDataSyncer
  DEFAULT_HISTORY_DAYS = 30
  RATE_PROVIDER_NAME = :synth
  PRICE_PROVIDER_NAME = :synth

  MissingExchangeRateError = Class.new(StandardError)
  InvalidExchangeRateDataError = Class.new(StandardError)
  MissingSecurityPriceError = Class.new(StandardError)
  InvalidSecurityPriceDataError = Class.new(StandardError)

  # Syncer can optionally be scoped.  Otherwise, it syncs all user data
  def initialize(family: nil, account: nil)
    @family = family
    @account = account
  end

  def sync_all(full_history: false, clear_cache: false)
    sync_exchange_rates(full_history: full_history, clear_cache: clear_cache)
    sync_prices(full_history: full_history, clear_cache: clear_cache)
  end

  def sync_exchange_rates(full_history: false, clear_cache: false)
    unless rate_provider
      Rails.logger.warn("No rate provider configured for MarketDataSyncer.sync_exchange_rates, skipping sync")
      return
    end

    # Finds distinct currency pairs
    entry_pairs = entries_scope.joins(:account)
                                  .where.not("entries.currency = accounts.currency")
                                  .select("entries.currency as source, accounts.currency as target")
                                  .distinct

    # All accounts in currency not equal to the family currency require exchange rates to show a normalized historical graph
    account_pairs = accounts_scope.joins(:family)
                                  .where.not("families.currency = accounts.currency")
                                  .select("accounts.currency as source, families.currency as target")
                                  .distinct

    pairs = (entry_pairs + account_pairs).uniq

    pairs.each do |pair|
      sync_exchange_rate(from: pair.source, to: pair.target, full_history: full_history)
    end
  end

  def sync_prices(full_history: false, clear_cache: false)
    unless price_provider
      Rails.logger.warn("No price provider configured for MarketDataSyncer.sync_prices, skipping sync")
      nil
    end

    securities_scope.each do |security|
      sync_security_price(security: security, full_history: full_history)
    end
  end

  def sync_security_price(security:, full_history:, clear_cache:)
    start_date = full_history ? find_oldest_required_price(security: security) : default_start_date

    Rails.logger.info("Syncing security price for: #{security.ticker}, start_date: #{start_date}, end_date: #{end_date}")

    fetched_prices = price_provider.fetch_security_prices(
      security,
      start_date: start_date,
      end_date: end_date
    )

    unless fetched_prices.success?
      error = MissingSecurityPriceError.new(
        "#{PRICE_PROVIDER_NAME} could not fetch security price for: #{security.ticker} between: #{start_date} and: #{Date.current}.  Provider error: #{fetched_prices.error.message}"
      )

      Rails.logger.warn(error.message)
      Sentry.capture_exception(error, level: :warning)

      return
    end

    prices_for_upsert = fetched_prices.data.map do |price|
      if price.security.nil? || price.date.nil? || price.price.nil? || price.currency.nil?
        error = InvalidSecurityPriceDataError.new(
          "#{PRICE_PROVIDER_NAME} returned invalid price data for security: #{security.ticker} on: #{price.date}.  Price data: #{price.inspect}"
        )

        Rails.logger.warn(error.message)
        Sentry.capture_exception(error, level: :warning)

        next
      end

      {
        security_id: price.security.id,
        date: price.date,
        price: price.price,
        currency: price.currency
      }
    end.compact

    Security::Price.upsert_all(
      prices_for_upsert,
      unique_by: %i[security_id date currency]
    )
  end

  def sync_exchange_rate(from:, to:, full_history:, clear_cache:)
    start_date = full_history ? find_oldest_required_rate(from_currency: from) : default_start_date

    Rails.logger.info("Syncing exchange rate from: #{from}, to: #{to}, start_date: #{start_date}, end_date: #{end_date}")

    fetched_rates = rate_provider.fetch_exchange_rates(
      from: from,
      to: to,
      start_date: start_date,
      end_date: end_date
    )

    unless fetched_rates.success?
      message = "#{RATE_PROVIDER_NAME} could not fetch exchange rate pair from: #{from} to: #{to} between: #{start_date} and: #{Date.current}.  Provider error: #{fetched_rates.error.message}"
      Rails.logger.warn(message)
      Sentry.capture_exception(MissingExchangeRateError.new(message))
      return
    end

    rates_for_upsert = fetched_rates.data.map do |rate|
      if rate.from.nil? || rate.to.nil? || rate.date.nil? || rate.rate.nil?
        message = "#{RATE_PROVIDER_NAME} returned invalid rate data for pair from: #{from} to: #{to} on: #{rate.date}.  Rate data: #{rate.inspect}"
        Rails.logger.warn(message)
        Sentry.capture_exception(InvalidExchangeRateDataError.new(message))
        next
      end

      {
        from_currency: rate.from,
        to_currency: rate.to,
        date: rate.date,
        rate: rate.rate
      }
    end.compact

    ExchangeRate.upsert_all(
      rates_for_upsert,
      unique_by: %i[from_currency to_currency date]
    )
  end

  private
    attr_reader :family, :account

    def accounts_scope
      return Account.where(id: account.id) if account
      return family.accounts if family
      Account.all
    end

    def entries_scope
      account&.entries || family&.entries || Entry.all
    end

    def securities_scope
      if account
        account.trades.joins(:security).where.not(securities: { exchange_operating_mic: nil })
      elsif family
        family.trades.joins(:security).where.not(securities: { exchange_operating_mic: nil })
      else
        Security.where.not(exchange_operating_mic: nil)
      end
    end

    def rate_provider
      Provider::Registry.for_concept(:exchange_rates).get_provider(RATE_PROVIDER_NAME)
    end

    def price_provider
      Provider::Registry.for_concept(:securities).get_provider(PRICE_PROVIDER_NAME)
    end

    def find_oldest_required_rate(from_currency:)
      entries_scope.where(currency: from_currency).minimum(:date) || default_start_date
    end

    def default_start_date
      DEFAULT_HISTORY_DAYS.days.ago.to_date
    end

    # Since we're querying market data from a US-based API, end date should always be today (EST)
    def end_date
      Date.current.in_time_zone("America/New_York").to_date
    end
end
