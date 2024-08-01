class Provider::Synth
  include Retryable

  def initialize(api_key)
    @api_key = api_key
  end

  def fetch_security_prices(ticker:, start_date:, end_date:)
    retrying Provider::Base.known_transient_errors do |on_last_attempt|
      response = Faraday.get("#{base_url}/tickers/#{ticker}/open-close") do |req|
        req.headers["Authorization"] = "Bearer #{@api_key}"
        req.params["start_date"] = start_date.to_s
        req.params["end_date"] = end_date.to_s
      end

      if response.success?
        prices = JSON.parse(response.body).dig("prices").map do |price|
          {
            date: price.dig("date"),
            price: price.dig("close").to_f,
            currency: "USD"
          }
        end

        SecurityPriceResponse.new \
          prices: prices,
          success?: true,
          raw_response: response.body
      else
        if on_last_attempt
          SecurityPriceResponse.new \
            success?: false,
            error: build_error(response),
            raw_response: response
        else
          raise build_error(response)
        end
      end
    end
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

    ExchangeRateResponse = Struct.new :rate, :success?, :error, :raw_response, keyword_init: true
    SecurityPriceResponse = Struct.new :prices, :success?, :error, :raw_response, keyword_init: true

    def base_url
      "https://api.synthfinance.com"
    end

    def build_error(response)
      Provider::Base::ProviderError.new(<<~ERROR)
        Failed to fetch data from #{self.class}
          Status: #{response.status}
          Body: #{response.body.inspect}
      ERROR
    end
end
