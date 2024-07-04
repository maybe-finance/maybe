class ExchangeRate < ApplicationRecord
  include Provided, Syncable

  validates :base_currency, :converted_currency, presence: true

  class << self
    def sync(syncable, start_date)
      required_rates = syncable.required_exchange_rates(start_date)
      puts "syncing exchange rates"
    end

    def find_rate(from:, to:, date:, cache: true)
      result = find_by \
        base_currency: from,
        converted_currency: to,
        date: date

      result || fetch_rate_from_provider(from:, to:, date:, cache:)
    end

    def find_rates(from:, to:, start_date:, end_date: Date.current, cache: true)
      rates = self.where(base_currency: from, converted_currency: to, date: start_date..end_date).to_a
      all_dates = (start_date..end_date).to_a.to_set
      existing_dates = rates.map(&:date).to_set
      missing_dates = all_dates - existing_dates

      fetch_rates_from_provider(from:, to:, dates: missing_dates, cache:)
    end
  end
end
