module ExchangeRate::Provided
  extend ActiveSupport::Concern
  include Providable

  class_methods do
    def fetch_rate_from_provider(from:, to:, date:)
      response = exchange_rates_provider.fetch_exchange_rate \
        from: Money::Currency.new(from).iso_code,
        to: Money::Currency.new(to).iso_code,
        date: date

      if response.success?
        ExchangeRate.new \
          base_currency: from,
          converted_currency: to,
          rate: response.rate,
          date: date
      else
        # do something else
      end
    end

    def fetch_historical_rates_from_provider
      # TODO: Implement
    end
  end
end
