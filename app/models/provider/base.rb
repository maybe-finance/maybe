class Provider::Base
  ProviderError = Class.new(StandardError)
  UnsupportedOperationError = Class.new(StandardError)

  TRANSIENT_NETWORK_ERRORS = [
    Faraday::TimeoutError,
    Faraday::ConnectionFailed,
    Faraday::SSLError,
    Faraday::ClientError,
    Faraday::ServerError
  ]

  class << self
    def known_transient_errors
      TRANSIENT_NETWORK_ERRORS + [ ProviderError ]
    end
  end

  def fetch_exchange_rate(...)
    raise Provider::Base::UnsupportedOperationError.new \
      "#{self.class.name} cannot fetch exchange rates"
  end

  def fetch_merchant_data(...)
    raise Provider::Base::UnsupportedOperationError.new \
      "#{self.class.name} cannot fetch merchant data"
  end

  def fetch_real_estate_valuation(...)
    raise Provider::Base::UnsupportedOperationError.new \
      "#{self.class.name} cannot fetch real estate valuations"
  end
end
