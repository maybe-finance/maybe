class Security::Price::Importer
  MissingSecurityPriceError = Class.new(StandardError)
  MissingStartPriceError    = Class.new(StandardError)

  def initialize(security:, security_provider:, start_date:, end_date:, clear_cache: false)
    @security          = security
    @security_provider = security_provider
    @start_date        = start_date
    @end_date          = normalize_end_date(end_date)
    @clear_cache       = clear_cache
  end

  # Constructs a daily series of prices for a single security over the date range.
  # Returns the number of rows upserted.
  def import_provider_prices
    if !clear_cache && all_prices_exist?
      Rails.logger.info("No new prices to sync for #{security.ticker} between #{start_date} and #{end_date}, skipping")
      return 0
    end

    if provider_prices.empty?
      Rails.logger.warn("Could not fetch prices for #{security.ticker} between #{start_date} and #{end_date} because provider returned no prices")
      return 0
    end

    prev_price_value = start_price_value

    unless prev_price_value.present?
      Rails.logger.error("Could not find a start price for #{security.ticker} on or before #{start_date}")

      Sentry.capture_exception(MissingStartPriceError.new("Could not determine start price for ticker")) do |scope|
        scope.set_tags(security_id: security.id)
        scope.set_context("security", {
          id: security.id,
          start_date: start_date
        })
      end

      return 0
    end

    gapfilled_prices = effective_start_date.upto(end_date).map do |date|
      db_price_value       = db_prices[date]&.price
      provider_price_value = provider_prices[date]&.price
      provider_currency    = provider_prices[date]&.currency

      chosen_price = if clear_cache
        provider_price_value || db_price_value   # overwrite when possible
      else
        db_price_value || provider_price_value   # fill gaps
      end

      # Gap-fill using LOCF (last observation carried forward)
      chosen_price ||= prev_price_value
      prev_price_value = chosen_price

      {
        security_id: security.id,
        date:        date,
        price:       chosen_price,
        currency:    provider_currency || prev_price_currency || db_price_currency || "USD"
      }
    end

    upsert_rows(gapfilled_prices)
  end

  private
    attr_reader :security, :security_provider, :start_date, :end_date, :clear_cache

    def provider_prices
      @provider_prices ||= begin
        provider_fetch_start_date = effective_start_date - 5.days

        response = security_provider.fetch_security_prices(
          symbol: security.ticker,
          exchange_operating_mic: security.exchange_operating_mic,
          start_date: provider_fetch_start_date,
          end_date:   end_date
        )

        if response.success?
          response.data.index_by(&:date)
        else
          Rails.logger.warn("#{security_provider.class.name} could not fetch prices for #{security.ticker} between #{provider_fetch_start_date} and #{end_date}. Provider error: #{response.error.message}")
          Sentry.capture_exception(MissingSecurityPriceError.new("Could not fetch prices for ticker"), level: :warning) do |scope|
            scope.set_tags(security_id: security.id)
            scope.set_context("security", { id: security.id, start_date: start_date, end_date: end_date })
          end

          {}
        end
      end
    end

    def db_prices
      @db_prices ||= Security::Price.where(security_id: security.id, date: start_date..end_date)
                                    .order(:date)
                                    .to_a
                                    .index_by(&:date)
    end

    def all_prices_exist?
      db_prices.count == expected_count
    end

    def expected_count
      (start_date..end_date).count
    end

    # Skip over ranges that already exist unless clearing cache
    def effective_start_date
      return start_date if clear_cache

      (start_date..end_date).detect { |d| !db_prices.key?(d) } || end_date
    end

    def start_price_value
      provider_price_value = provider_prices.select { |date, _| date <= start_date }
                                            .max_by { |date, _| date }
                                            &.last&.price
      db_price_value       = db_prices[start_date]&.price
      provider_price_value || db_price_value
    end

    def upsert_rows(rows)
      batch_size         = 200
      total_upsert_count = 0

      rows.each_slice(batch_size) do |batch|
        ids = Security::Price.upsert_all(
          batch,
          unique_by: %i[security_id date currency],
          returning: [ "id" ]
        )
        total_upsert_count += ids.count
      end

      total_upsert_count
    end

    def db_price_currency
      db_prices.values.first&.currency
    end

    def prev_price_currency
      @prev_price_currency ||= provider_prices.values.first&.currency
    end

    # Clamp to today (EST) so we never call our price API for a future date (our API is in EST/EDT timezone)
    def normalize_end_date(requested_end_date)
      today_est = Date.current.in_time_zone("America/New_York").to_date
      [ requested_end_date, today_est ].min
    end
end
