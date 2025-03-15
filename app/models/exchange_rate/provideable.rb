# Defines the interface an exchange rate provider must implement
module ExchangeRate::Provideable
  extend ActiveSupport::Concern

  FetchRateData = Data.define(:rate)
  FetchRatesData = Data.define(:rates)

  def fetch_exchange_rate(from:, to:, date:)
    raise NotImplementedError, "Subclasses must implement #fetch_exchange_rate"
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    raise NotImplementedError, "Subclasses must implement #fetch_exchange_rates"
  end
end
