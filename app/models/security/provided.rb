module Security::Provided
  extend ActiveSupport::Concern

  class_methods do
    def provider
      registry = Provider::Registry.for_concept(:securities)
      registry.get_provider(:synth)
    end

    def search_provider(symbol, country_code: nil, exchange_operating_mic: nil)
      return [] if symbol.blank? || symbol.length < 2

      response = provider.search_securities(symbol, country_code: country_code, exchange_operating_mic: exchange_operating_mic)

      if response.success?
        response.data.map do |provider_security|
          # Need to map to domain model so Combobox can display via to_combobox_option
          Security.new(
            ticker: provider_security.symbol,
            name: provider_security.name,
            logo_url: provider_security.logo_url,
            exchange_operating_mic: provider_security.exchange_operating_mic,
          )
        end
      else
        []
      end
    end
  end

  def find_or_fetch_price(date: Date.current, cache: true)
    price = prices.find_by(date: date)

    return price if price.present?

    # Make sure we have a data provider before fetching
    return nil unless provider.present?
    response = provider.fetch_security_price(self, date: date)

    return nil unless response.success? # Provider error

    price = response.data
    Security::Price.find_or_create_by!(
      security_id: price.security.id,
      date: price.date,
      price: price.price,
      currency: price.currency
    ) if cache
    price
  end

  def sync_provider_details(clear_cache: false)
    unless provider.present?
      Rails.logger.warn("No provider configured for Security.sync_provider_details")
      return
    end

    if self.name.present? && self.logo_url.present? && !clear_cache
      return
    end

    response = provider.fetch_security_info(
      symbol: ticker,
      exchange_operating_mic: exchange_operating_mic
    )

    if response.success?
      update(
        name: response.data.name,
        logo_url: response.data.logo_url,
      )
    else
      err = StandardError.new("Failed to fetch security info for #{ticker} from #{provider.class.name}: #{response.error.message}")
      Rails.logger.warn(err.message)
      Sentry.capture_exception(err, level: :warning)
    end
  end

  def sync_provider_prices(start_date:, end_date:, clear_cache: false)
    unless provider.present?
      Rails.logger.warn("No provider configured for Security.sync_provider_prices")
      return 0
    end

    Security::Price::Syncer.new(
      security: self,
      security_provider: provider,
      start_date: start_date,
      end_date: end_date,
      clear_cache: clear_cache
    ).sync_provider_prices
  end

  private
    def provider
      self.class.provider
    end
end
