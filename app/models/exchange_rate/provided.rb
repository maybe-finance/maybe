module ExchangeRate::Provided
  extend ActiveSupport::Concern
  include Providable

  class_methods do
    private
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
          raise response.error
        end
      end
  end
end
