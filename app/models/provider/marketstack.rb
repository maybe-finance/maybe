class Provider::Marketstack
  include Retryable

  def initialize(api_key)
    @api_key = api_key
  end

  def fetch_security_prices(ticker:, start_date:, end_date:)
    prices = paginate("#{base_url}/eod", {
      symbols: ticker,
      date_from: start_date.to_s,
      date_to: end_date.to_s
    }) do |body|
      body.dig("data").map do |price|
        {
          date: price["date"],
          price: price["close"]&.to_f,
          currency: "USD"
        }
      end
    end

    SecurityPriceResponse.new(
      prices: prices,
      success?: true,
      raw_response: prices.to_json
    )
  rescue StandardError => error
    SecurityPriceResponse.new(
      success?: false,
      error: error,
      raw_response: error
    )
  end

  def fetch_tickers(exchange_mic: nil)
    url = exchange_mic ? "#{base_url}/tickers?exchange=#{exchange_mic}" : "#{base_url}/tickers"
    tickers = paginate(url) do |body|
      body.dig("data").map do |ticker|
        {
          name: ticker["name"],
          symbol: ticker["symbol"],
          exchange: exchange_mic || ticker.dig("stock_exchange", "mic"),
          country_code: ticker.dig("stock_exchange", "country_code")
        }
      end
    end

    TickerResponse.new(
      tickers: tickers,
      success?: true,
      raw_response: tickers.to_json
    )
  rescue StandardError => error
    TickerResponse.new(
      success?: false,
      error: error,
      raw_response: error
    )
  end

  private

    attr_reader :api_key

    SecurityPriceResponse = Struct.new(:prices, :success?, :error, :raw_response, keyword_init: true)
    TickerResponse = Struct.new(:tickers, :success?, :error, :raw_response, keyword_init: true)

    def base_url
      "https://api.marketstack.com/v1"
    end

    def client
      @client ||= Faraday.new(url: base_url) do |faraday|
        faraday.params["access_key"] = api_key
      end
    end

    def build_error(response)
      Provider::Base::ProviderError.new(<<~ERROR)
        Failed to fetch data from #{self.class}
          Status: #{response.status}
          Body: #{response.body.inspect}
      ERROR
    end

    def fetch_page(url, page, params = {})
      client.get(url) do |req|
        params.each { |k, v| req.params[k.to_s] = v.to_s }
        req.params["offset"] = (page - 1) * 100 # Marketstack uses offset-based pagination
        req.params["limit"] = 10000 # Maximum allowed by Marketstack
      end
    end

    def paginate(url, params = {})
      results = []
      page = 1
      total_results = Float::INFINITY

      while results.length < total_results
        response = fetch_page(url, page, params)

        if response.success?
          body = JSON.parse(response.body)
          page_results = yield(body)
          results.concat(page_results)

          total_results = body.dig("pagination", "total")
          page += 1
        else
          raise build_error(response)
        end

        break if results.length >= total_results
      end

      results
    end
end
