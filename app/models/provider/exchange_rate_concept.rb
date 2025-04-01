module Provider::ExchangeRateConcept
  extend ActiveSupport::Concern

  Rate = Data.define(:date, :from, :to, :rate)

  def fetch_exchange_rate(from:, to:, date:)
    raise NotImplementedError, "Subclasses must implement #fetch_exchange_rate"
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    raise NotImplementedError, "Subclasses must implement #fetch_exchange_rates"
  end
end
