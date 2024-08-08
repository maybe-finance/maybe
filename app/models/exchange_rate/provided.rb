module ExchangeRate::Provided
  extend ActiveSupport::Concern

  include Providable

  class_methods do
    private

      def fetch_rates_from_provider(from:, to:, start_date:, end_date: Date.current, cache: false)
        return [] unless exchange_rates_provider.present?

        response = exchange_rates_provider.fetch_exchange_rate_for_date_range \
          from: from,
          to: to,
          date_start: start_date,
          date_end: end_date

        if response.success?
          response.rates.map do |exchange_rate|
            rate = ExchangeRate.new \
              from_currency: from,
              to_currency: to,
              date: exchange_rate.date.to_date,
              rate: exchange_rate.rate

            rate.save! if cache
            rate
          rescue ActiveRecord::RecordNotUnique
            next
          end
        else
          []
        end
      end

      def fetch_rate_from_provider(from:, to:, date:, cache: false)
        return nil unless exchange_rates_provider.present?

        response = exchange_rates_provider.fetch_exchange_rate \
          from: from,
          to: to,
          date: date

        if response.success?
          rate = ExchangeRate.new \
            from_currency: from,
            to_currency: to,
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
