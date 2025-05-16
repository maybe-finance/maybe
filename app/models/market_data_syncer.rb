class MarketDataSyncer
  DEFAULT_HISTORY_DAYS = 30
  RATE_PROVIDER_NAME = :synth
  PRICE_PROVIDER_NAME = :synth

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
      start_date = full_history ? find_oldest_required_rate(from_currency: pair.source) : default_start_date

      ExchangeRate.sync_provider_rates(
        from: pair.source,
        to: pair.target,
        start_date: start_date,
        end_date: end_date,
        clear_cache: clear_cache
      )
    end
  end

  def sync_prices(full_history: false, clear_cache: false)
    unless price_provider
      Rails.logger.warn("No price provider configured for MarketDataSyncer.sync_prices, skipping sync")
      nil
    end

    securities_scope.each do |security|
      start_date = full_history ? find_oldest_required_price(security: security) : default_start_date

      security.sync_provider_prices(start_date: start_date, end_date: end_date, clear_cache: clear_cache)
      security.sync_provider_details(clear_cache: clear_cache)
    end
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
