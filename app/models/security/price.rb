class Security::Price < ApplicationRecord
  include Provided

  belongs_to :security

  before_save :upcase_ticker

  validates :ticker, presence: true, uniqueness: { scope: :date, case_sensitive: false }

  class << self
    def find_price(security:, date:, cache: true)
      result = find_by(security:, date:)

      result || fetch_price_from_provider(security:, date:, cache:)
    end

    def find_prices(security:, start_date:, end_date: Date.current, cache: true)
      prices = where(security_id: security.id, date: start_date..end_date).to_a
      all_dates = (start_date..end_date).to_a.to_set
      existing_dates = prices.map(&:date).to_set
      missing_dates = (all_dates - existing_dates).sort

      if missing_dates.any?
        prices += fetch_prices_from_provider(
          ticker: security.ticker,
          exchange_mic: security.exchange_mic,
          start_date: missing_dates.first,
          end_date: missing_dates.last,
          cache: cache
        )
      end

      prices
    end
  end

  private
    def upcase_ticker
      self.ticker = ticker.upcase
    end
end
