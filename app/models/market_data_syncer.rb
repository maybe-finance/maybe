class MarketDataSyncer
  # By default, our graphs show 1M as the view, so by fetching 31 days,
  # we ensure we can always show an accurate default graph
  SNAPSHOT_DAYS = 31

  InvalidModeError = Class.new(StandardError)

  def initialize(mode: :full, clear_cache: false)
    @mode = set_mode!(mode)
    @clear_cache = clear_cache
  end

  def sync
    sync_prices
    sync_exchange_rates
  end

  # Syncs historical security prices (and details)
  def sync_prices
    unless Security.provider
      Rails.logger.warn("No provider configured for MarketDataSyncer.sync_prices, skipping sync")
      return
    end

    Security.where.not(exchange_operating_mic: nil).find_each do |security|
      security.sync_provider_prices(
        start_date: get_first_required_price_date(security),
        end_date: end_date,
        clear_cache: clear_cache
      )

      security.sync_provider_details(clear_cache: clear_cache)
    end
  end

  def sync_exchange_rates
    unless ExchangeRate.provider
      Rails.logger.warn("No provider configured for MarketDataSyncer.sync_exchange_rates, skipping sync")
      return
    end

    required_exchange_rate_pairs.each do |pair|
      # pair is a Hash with keys :source, :target, and :start_date
      start_date = snapshot? ? default_start_date : pair[:start_date]

      ExchangeRate.sync_provider_rates(
        from: pair[:source],
        to: pair[:target],
        start_date: start_date,
        end_date: end_date,
        clear_cache: clear_cache
      )
    end
  end

  private
    attr_reader :mode, :clear_cache

    def snapshot?
      mode.to_sym == :snapshot
    end

    # Builds a unique list of currency pairs with the earliest date we need
    # exchange rates for.
    #
    # Returns: Array of Hashes – [{ source:, target:, start_date: }, ...]
    def required_exchange_rate_pairs
      pair_dates = {} # { [source, target] => earliest_date }

      # 1. ENTRY-BASED PAIRS – we need rates from the first entry date
      Entry.joins(:account)
           .where.not("entries.currency = accounts.currency")
           .group("entries.currency", "accounts.currency")
           .minimum("entries.date")
           .each do |(source, target), date|
        key = [ source, target ]
        pair_dates[key] = [ pair_dates[key], date ].compact.min
      end

      # 2. ACCOUNT-BASED PAIRS – use the account's oldest entry date
      account_first_entry_dates = Entry.group(:account_id).minimum(:date)

      Account.joins(:family)
             .where.not("families.currency = accounts.currency")
             .select("accounts.id, accounts.currency AS source, families.currency AS target")
             .find_each do |account|
        earliest_entry_date = account_first_entry_dates[account.id]

        chosen_date = [ earliest_entry_date, default_start_date ].compact.min

        key = [ account.source, account.target ]
        pair_dates[key] = [ pair_dates[key], chosen_date ].compact.min
      end

      # Convert to array of hashes for ease of use
      pair_dates.map do |(source, target), date|
        { source: source, target: target, start_date: date }
      end
    end

    def get_first_required_price_date(security)
      return default_start_date if snapshot?

      Trade.with_entry.where(security: security).minimum(:date)
    end

    # An approximation that grabs more than we likely need, but simplifies the logic
    def get_first_required_exchange_rate_date(from_currency:)
      return default_start_date if snapshot?

      Entry.where(currency: from_currency).minimum(:date)
    end

    def default_start_date
      SNAPSHOT_DAYS.days.ago.to_date
    end

    # Since we're querying market data from a US-based API, end date should always be today (EST)
    def end_date
      Date.current.in_time_zone("America/New_York").to_date
    end

    def set_mode!(mode)
      valid_modes = [ :full, :snapshot ]

      unless valid_modes.include?(mode.to_sym)
        raise InvalidModeError, "Invalid mode for MarketDataSyncer, can only be :full or :snapshot, but was #{mode}"
      end

      mode.to_sym
    end
end
