class Provider::Synth
  def initialize(api_key)
    @api_key = api_key
  end

  def fetch_exchange_rate(from:, to:, date:)
    response = Faraday.get(base_url) do |req|
      req.headers["Authorization"] = "Bearer #{api_key}"
      req.params["date"] = date.to_s
      req.params["from"] = from
      req.params["to"] = to
    end

    if response.success?
      Response.new \
        rate: JSON.parse(response.body).dig("data", "rates", to),
        raw_response: response
    else
      raise Provider::Base::ProviderError, <<~ERROR
        Failed to fetch exchange rate from #{self.class}
          Status: #{response.status}
          Response: #{response.body.inspect}
      ERROR
    end
  end

  private
    attr_reader :api_key

    Response = Struct.new(:rate, :raw_response, keyword_init: true)

    def base_url
      "https://api.synthfinance.com/rates/historical"
    end
end
