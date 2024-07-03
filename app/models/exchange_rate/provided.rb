module ExchangeRate::Provided
  extend ActiveSupport::Concern
  include Providable

  class_methods do
    private

      def fetch_rates_from_provider(from:, to:, dates:, cache: false)
        dates.map do |date|
          fetch_rate_from_provider from:, to:, date:, cache:
        end.compact
      end

      def fetch_rate_from_provider(from:, to:, date:, cache: false)
        return nil unless exchange_rates_provider.present?

        response = exchange_rates_provider.fetch_exchange_rate \
          from: from,
          to: to,
          date: date

        if response.success?
          rate = ExchangeRate.new \
            base_currency: from,
            converted_currency: to,
            rate: response.rate,
            date: date

          rate.save! if cache
          rate
        else
          nil
        end
      end
  end
end
