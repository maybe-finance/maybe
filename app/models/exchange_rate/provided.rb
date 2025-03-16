module ExchangeRate::Provided
  extend ActiveSupport::Concern

  class_methods do
    def provider
      Providers.synth
    end

    def find_or_fetch_rate(from:, to:, date: Date.current, cache: true)
      rate = find_by(from_currency: from, to_currency: to, date: date)
      return rate if rate.present?

      response = provider.fetch_exchange_rate(from: from, to: to, date: date)

      rate = response.data.rate
      rate.save! if cache
      rate
    end

    def sync_provider_rates(from:, to:, start_date:, end_date: Date.current)
      # TODO
    end
  end
end
