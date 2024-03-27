
class Provider::Base
  ProviderError = Class.new(StandardError)

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
end
