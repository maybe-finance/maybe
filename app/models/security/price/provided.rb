module Security::Price::Provided
  extend ActiveSupport::Concern

  include Synthable

  class_methods do
    def provider
      synth_client
    end

    private
      def fetch_price_from_provider(security:, date:, cache: false)
        return nil unless provider.present?
        return nil unless security.has_prices?

        response = provider.fetch_security_prices \
          ticker: security.ticker,
          mic_code: security.exchange_operating_mic,
          start_date: date,
          end_date: date

        if response.success? && response.prices.size > 0
          price = Security::Price.new \
            security: security,
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
        return [] unless provider.present?
        return [] unless security
        return [] unless security.has_prices?

        response = provider.fetch_security_prices \
          ticker: security.ticker,
          mic_code: security.exchange_operating_mic,
          start_date: start_date,
          end_date: end_date

        if response.success?
          response.prices.map do |price|
            new_price = Security::Price.find_or_initialize_by(
              security: security,
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
