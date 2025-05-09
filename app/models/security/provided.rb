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

    fetched_prices = response.data.map do |price|
      {
        security_id: price.security.id,
        date: price.date,
        price: price.price,
        currency: price.currency
      }
    end

    valid_prices = fetched_prices.reject do |price|
      is_invalid = price[:date].nil? || price[:price].nil? || price[:currency].nil?
      if is_invalid
        Rails.logger.warn("Invalid price data for security_id=#{id}: Missing required fields in price record: #{price.inspect}")
      end
      is_invalid
    end

    valid_prices.each_slice(100) do |batch|
      retries ||= 0

      begin
        Security::Price.upsert_all(batch, unique_by: %i[security_id date currency])
      rescue => e
        if retries < 3
          retries += 1
          sleep(1)
          Rails.logger.warn("Retrying upsert of #{batch.size} prices for security_id=#{id} ticker=#{ticker} retry=#{retries} error=#{e.message}")
          retry
        else
          raise e
        end
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

  private
    def provider
      self.class.provider
    end
end
