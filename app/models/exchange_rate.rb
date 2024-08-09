class ExchangeRate < ApplicationRecord
  include Provided

  validates :from_currency, :to_currency, :date, :rate, presence: true

  class << self
    def find_rate(from:, to:, date:, cache: true)
      result = find_by \
        from_currency: from,
        to_currency: to,
        date: date

      result || fetch_rate_from_provider(from:, to:, date:, cache:)
    end

    def find_rates(from:, to:, start_date:, end_date: Date.current, cache: true)
      rates = self.where(from_currency: from, to_currency: to, date: start_date..end_date).to_a
      all_dates = (start_date..end_date).to_a
      existing_dates = rates.map(&:date)
      missing_dates = all_dates - existing_dates
      if missing_dates.any?
        rates += fetch_rates_from_provider(from:, to:, start_date: missing_dates.first, end_date: missing_dates.last, cache:)
      end

      rates
    end
  end
end
