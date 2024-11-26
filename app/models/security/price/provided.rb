module Security::Price::Provided
  extend ActiveSupport::Concern

  include Providable

  class_methods do
    private

      def fetch_price_from_provider(security:, date:, cache: false)
        return nil unless security_prices_provider.present?

        response = security_prices_provider.fetch_security_prices \
          ticker: security.ticker,
          mic_code: security.exchange_mic,
          start_date: date,
          end_date: date

        if response.success? && response.prices.size > 0
          price = Security::Price.new \
            security: security,
            ticker: security.ticker,
            date: response.prices.first[:date],
            price: response.prices.first[:price],
            currency: response.prices.first[:currency]

          price.save! if cache
          price
        else
          nil
        end
      end

      def fetch_prices_from_provider(security:, start_date:, end_date:, cache: false)
        return [] unless security_prices_provider.present?
        return [] unless security

        response = security_prices_provider.fetch_security_prices \
          ticker: security.ticker,
          mic_code: security.exchange_mic,
          start_date: start_date,
          end_date: end_date

        if response.success?
          response.prices.map do |price|
            new_price = Security::Price.find_or_initialize_by(
              security: security,
              ticker: security.ticker,
              date: price[:date]
            ) do |p|
              p.price = price[:price]
              p.currency = price[:currency]
            end

            new_price.save! if cache && new_price.new_record?
            new_price
          end
        else
          []
        end
      end
  end
end
