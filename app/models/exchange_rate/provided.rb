module ExchangeRate::Provided
  extend ActiveSupport::Concern

  class_methods do
    def provider
      registry = Provider::Registry.for_concept(:exchange_rates)
      registry.get_provider(:synth)
    end

    def find_or_fetch_rate(from:, to:, date: Date.current, cache: true)
      rate = find_by(from_currency: from, to_currency: to, date: date)
      return rate if rate.present?

      return nil unless provider.present? # No provider configured (some self-hosted apps)

      response = provider.fetch_exchange_rate(from: from, to: to, date: date)

      return nil unless response.success? # Provider error

      rate = response.data
      ExchangeRate.find_or_create_by!(
        from_currency: rate.from,
        to_currency: rate.to,
        date: rate.date,
        rate: rate.rate
      ) if cache
      rate
    end

    def sync_provider_rates(from:, to:, start_date:, end_date: Date.current)
      unless provider.present?
        Rails.logger.warn("No provider configured for ExchangeRate.sync_provider_rates")
        return 0
      end

      fetched_rates = provider.fetch_exchange_rates(from: from, to: to, start_date: start_date, end_date: end_date)

      unless fetched_rates.success?
        Rails.logger.error("Provider error for ExchangeRate.sync_provider_rates: #{fetched_rates.error}")
        return 0
      end

      rates_data = fetched_rates.data.map do |rate|
        {
          from_currency: rate.from,
          to_currency: rate.to,
          date: rate.date,
          rate: rate.rate
        }
      end

      ExchangeRate.upsert_all(rates_data, unique_by: %i[from_currency to_currency date])
    end
  end
end
