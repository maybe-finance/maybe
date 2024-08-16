class Issue::ExchangeRatesMissing < Issue
  store_accessor :data, :from_currency, :to_currency, :dates

  validates :from_currency, :to_currency, :dates, presence: true

  def stale?
    if dates.length == 1
      ExchangeRate.find_rate(from: from_currency, to: to_currency, date: dates.first).present?
    else
      sorted_dates = dates.sort
      rates = ExchangeRate.find_rates(from: from_currency, to: to_currency, start_date: sorted_dates.first, end_date: sorted_dates.last)
      rates.length == dates.length
    end
  end
end
