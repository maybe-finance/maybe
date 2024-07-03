class Provider::Synth
  include Retryable

  def initialize(api_key)
    @api_key = api_key
  end

  def fetch_exchange_rate(from:, to:, date:)
    retrying Provider::Base.known_transient_errors do |on_last_attempt|
      response = Faraday.get("#{base_url}/rates/historical") do |req|
        req.headers["Authorization"] = "Bearer #{api_key}"
        req.params["date"] = date.to_s
        req.params["from"] = from
        req.params["to"] = to
      end

      if response.success?
        Provider::Base::ExchangeRateResponse.new \
          rate: JSON.parse(response.body).dig("data", "rates", to),
          success?: true,
          raw_response: response
      else
        if on_last_attempt
          Provider::Base::ExchangeRateResponse.new \
            success?: false,
            error: build_error(response),
            raw_response: response
        else
          raise build_error(response)
        end
      end
    end
  end

  private
    attr_reader :api_key

    def base_url
      "https://api.synthfinance.com"
    end

    def build_error(response)
      Provider::Base::ProviderError.new(<<~ERROR)
        Failed to fetch exchange rate from #{self.class}
          Status: #{response.status}
          Body: #{response.body.inspect}
      ERROR
    end
end
