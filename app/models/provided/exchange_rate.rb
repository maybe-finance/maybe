class Provided::ExchangeRate
  include Providable, Retryable

  def initialize
    @provider = exchange_rates_provider
  end

  def fetch(from:, to:, date:)
    retrying Provider::Base.known_transient_errors do
      response = provider.fetch_exchange_rate(from:, to:, date:)

      ExchangeRate.new \
        base_currency: from,
        converted_currency: to,
        rate: response.rate,
        date: date
    end
  end

  private
    attr_reader :provider
end
