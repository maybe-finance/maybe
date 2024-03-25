class Provider::Synth < Provider::Base
  def initialize(api_key)
    @api_key = api_key
  end

  def fetch_exchange_rate(from:, to:, date:)
    response = Faraday.get("#{base_url}/rates/historical") do |req|
      req.headers["Authorization"] = "Bearer #{api_key}"
      req.params["date"] = date.to_s
      req.params["from"] = from
      req.params["to"] = to
    end

    if response.success?
      ExchangeRateResponse.new \
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

  def fetch_merchant_data(description:)
    response = Faraday.get("#{base_url}/enrich") do |req|
      req.headers["Authorization"] = "Bearer #{api_key}"
      req.params["description"] = description
    end

    if response.success?
      JSON.parse(response.body).then do |body|
        MerchantDataResponse.new \
          name: body.dig("data", "merchant"),
          website: body.dig("data", "website"),
          logo_url: body.dig("data", "icon"),
          raw_response: response
      end
    else
      raise Provider::Base::ProviderError, <<~ERROR
        Failed to fetch merchant data from #{self.class}
          Status: #{response.status}
          Response: #{response.body.inspect}
      ERROR
    end
  end

  private
    attr_reader :api_key

    ExchangeRateResponse = Struct.new(:rate, :raw_response, keyword_init: true)
    MerchantDataResponse = Struct.new(:name, :website, :logo_url, :raw_response, keyword_init: true)

    def base_url
      "https://api.synthfinance.com"
    end
end
