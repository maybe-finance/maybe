module Security::Provided
  extend ActiveSupport::Concern

  class_methods do
    def provider
      Providers.synth
    end

    def search_provider(symbol, country_code: nil, exchange_operating_mic: nil)
      return [] if symbol.blank? || symbol.length < 2

      response = provider.search_securities(symbol, country_code: country_code, exchange_operating_mic: exchange_operating_mic)

      if response.success?
        response.data.securities
      else
        []
      end
    end
  end

  def sync_provider_prices(start_date:, end_date: Date.current)
    unless has_prices?
      Rails.logger.warn("Security id=#{id} ticker=#{ticker} is not known by provider, skipping price sync")
      return 0
    end

    unless provider.present?
      Rails.logger.warn("No security provider configured, cannot sync prices for id=#{id} ticker=#{ticker}")
      return 0
    end

    response = provider.fetch_security_prices(self, start_date: start_date, end_date: end_date)

    unless response.success?
      Rails.logger.error("Provider error for sync_provider_prices with id=#{id} ticker=#{ticker}: #{response.error}")
      return 0
    end

    fetched_prices = response.data.prices.map do |price|
      price.attributes.slice("security_id", "date", "price", "currency")
    end

    valid_prices = fetched_prices.reject do |price|
      is_invalid = price["date"].nil? || price["price"].nil? || price["currency"].nil?
      if is_invalid
        Rails.logger.warn("Invalid price data for security_id=#{id}: Missing required fields in price record: #{price.inspect}")
      end
      is_invalid
    end

    Security::Price.upsert_all(valid_prices, unique_by: %i[security_id date currency])
  end

  def find_or_fetch_price(date: Date.current, cache: true)
    price = prices.find_by(date: date)

    return price if price.present?

    response = provider.fetch_security_price(self, date: date)

    return nil unless response.success? # Provider error

    price = response.data.price
    price.save! if cache
    price
  end

  private
    def provider
      self.class.provider
    end
end
