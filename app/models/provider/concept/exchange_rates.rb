module Provider::Concept::ExchangeRates
  extend ActiveSupport::Concern

  def fetch_exchange_rate(from:, to:, date:)
    raise NotImplementedError, "Subclasses must implement #fetch_exchange_rate"
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    raise NotImplementedError, "Subclasses must implement #fetch_exchange_rates"
  end

  private
    ProviderRate = Data.define(:from, :to, :date, :rate)
    FetchExchangeRate = Data.define(:rate)
    FetchExchangeRates = Data.define(:rates)
end
