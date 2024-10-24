class Provider::Marketstack
  include Retryable

  def initialize(api_key)
    @api_key = api_key
  end

  def fetch_tickers(exchange_mic:)
    params = {}
    params[:exchange] = exchange_mic if exchange_mic.present?

    tickers = paginate("/v1/tickers", params) do |body|
      body.dig("data").map do |ticker|
        {
          ticker: ticker.dig("symbol"),
          name: ticker.dig("name"),
          country_code: ticker.dig("country_code"),
          stock_exchange: StockExchange.find_by(mic: ticker.dig("exchange_mic"))
        }
      end
    end
  end

  private

    attr_reader :api_key

    def base_url
      "https://api.marketstack.com/v1"
    end

    def fetch_page(url, offset, params = {})
      client.get(url) do |req|
        req.params["access_key"] = api_key
        params.each { |k, v| req.params[k.to_s] = v.to_s }
        req.params["offset"] = offset
        req.params["limit"] = 10000
      end
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

    def paginate(url, params = {})
      results = []
      offset = 0
      total = nil

      loop do
        response = fetch_page(url, offset, params)

        if response.success?
          body = JSON.parse(response.body)
          page_results = yield(body)
          results.concat(page_results)

          total ||= body.dig("pagination", "total")
          offset += body.dig("pagination", "limit")

          break if offset >= total
        else
          raise build_error(response)
        end
      end

      results
    end
end
