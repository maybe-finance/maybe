class Provider::Synth
  include Retryable

  def initialize(api_key)
    @api_key = api_key || ENV["SYNTH_API_KEY"]
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
        ExchangeRateResponse.new \
          rate: JSON.parse(response.body).dig("data", "rates", to),
          success?: true,
          raw_response: response
      else
        if on_last_attempt
          ExchangeRateResponse.new \
            rate: nil,
            success?: false,
            raw_response: response
        else
          raise_error "Failed to fetch exchange rate from #{self.class}", response
        end
      end
    end
  end

  def fetch_merchant_data(description:)
    retrying Provider::Base.known_transient_errors do |on_last_attempt|
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
            success?: true,
            raw_response: response
        end
      else
        if on_last_attempt
          MerchantDataResponse.new \
            name: nil,
            website: nil,
            logo_url: nil,
            success?: false,
            raw_response: response
        else
          raise_error "Failed to fetch merchant data from #{self.class}", response
        end
      end
    end
  end

  private
    attr_reader :api_key

    ExchangeRateResponse = Struct.new(:rate, :success?, :raw_response, keyword_init: true)
    MerchantDataResponse = Struct.new(:name, :website, :logo_url, :success?, :raw_response, keyword_init: true)

    def base_url
      "https://api.synthfinance.com"
    end

    def raise_error(message, response)
      raise Provider::Base::ProviderError, <<~ERROR
        #{message}
          Status: #{response.status}
          Body: #{response.body.inspect}
      ERROR
    end
end
