class ExchangeRate < ApplicationRecord
  validates :base_currency, :converted_currency, presence: true

  class << self
    def find_rate!(from:, to:, date:)
      find_by! \
        base_currency: Money::Currency.new(from).iso_code,
        converted_currency: Money::Currency.new(to).iso_code,
        date: date
    end

    def find_rate_or_fetch(from:, to:, date:)
      find_rate! from:, to:, date:
    rescue
      fetch_rate_from_provider(from:, to:, date:).tap(&:save!)
    end

    def get_rate_series(from, to, date_range)
      where(base_currency: from, converted_currency: to, date: date_range).order(:date)
    end

    private
      def fetch_rate_from_provider(from:, to:, date:)
        Provided::ExchangeRate.new.fetch(from:, to:, date:)
      end
  end
end
