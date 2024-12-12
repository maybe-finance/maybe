class Provider::Synth
  include Retryable

  def initialize(api_key)
    @api_key = api_key
  end

  def healthy?
    response = client.get("#{base_url}/user")
    JSON.parse(response.body).dig("id").present?
  end

  def usage
    response = client.get("#{base_url}/user")

    if response.status == 401
      return UsageResponse.new(
        success?: false,
        error: "Unauthorized: Invalid API key",
        raw_response: response
      )
    end

    parsed = JSON.parse(response.body)

    remaining = parsed.dig("api_calls_remaining")
    limit = parsed.dig("api_limit")
    used = limit - remaining

    UsageResponse.new(
      used: used,
      limit: limit,
      utilization: used.to_f / limit * 100,
      plan: parsed.dig("plan"),
      success?: true,
      raw_response: response
    )
  rescue StandardError => error
    UsageResponse.new(
      success?: false,
      error: error,
      raw_response: error
    )
  end

  def fetch_security_prices(ticker:, start_date:, end_date:, mic_code: nil)
    params = {
      start_date: start_date,
      end_date: end_date
    }

    params[:mic_code] = mic_code if mic_code.present?

    prices = paginate(
      "#{base_url}/tickers/#{ticker}/open-close",
      params
    ) do |body|
      body.dig("prices").map do |price|
        {
          date: price.dig("date"),
          price: price.dig("close")&.to_f || price.dig("open")&.to_f,
          currency: price.dig("currency") || "USD"
        }
      end
    end

    SecurityPriceResponse.new \
      prices: prices,
      success?: true,
      raw_response: prices.to_json
  rescue StandardError => error
    SecurityPriceResponse.new \
      success?: false,
      error: error,
      raw_response: error
  end

  def fetch_exchange_rate(from:, to:, date:)
    retrying Provider::Base.known_transient_errors do |on_last_attempt|
      response = client.get("#{base_url}/rates/historical") do |req|
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

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    exchange_rates = paginate(
      "#{base_url}/rates/historical-range",
      from: from,
      to: to,
      date_start: start_date.to_s,
      date_end: end_date.to_s
    ) do |body|
      body.dig("data").map do |exchange_rate|
        {
          date: exchange_rate.dig("date"),
          rate: exchange_rate.dig("rates", to)
        }
      end
    end

    ExchangeRatesResponse.new \
      rates: exchange_rates,
      success?: true,
      raw_response: exchange_rates.to_json
  rescue StandardError => error
    ExchangeRatesResponse.new \
      success?: false,
      error: error,
      raw_response: error
  end

  def search_securities(query:, dataset: "limited", country_code:)
    response = client.get("#{base_url}/tickers/search") do |req|
      req.params["name"] = query
      req.params["dataset"] = dataset
      req.params["country_code"] = country_code
    end

    parsed = JSON.parse(response.body)

    securities = parsed.dig("data").map do |security|
      {
        ticker: security.dig("symbol"),
        name: security.dig("name"),
        logo_url: security.dig("logo_url"),
        exchange_acronym: security.dig("exchange", "acronym"),
        exchange_mic: security.dig("exchange", "mic_code"),
        country_code: security.dig("exchange", "country_code")
      }
    end

    SearchSecuritiesResponse.new \
      securities: securities,
      success?: true,
      raw_response: response
  end

  def fetch_security_info(ticker:, mic_code:)
    response = client.get("#{base_url}/tickers/#{ticker}") do |req|
      req.params["mic_code"] = mic_code
    end

    parsed = JSON.parse(response.body)

    SecurityInfoResponse.new \
      info: parsed.dig("data"),
      success?: true,
      raw_response: response
  end

  private

    attr_reader :api_key

    ExchangeRateResponse = Struct.new :rate, :success?, :error, :raw_response, keyword_init: true
    SecurityPriceResponse = Struct.new :prices, :success?, :error, :raw_response, keyword_init: true
    ExchangeRatesResponse = Struct.new :rates, :success?, :error, :raw_response, keyword_init: true
    UsageResponse = Struct.new :used, :limit, :utilization, :plan, :success?, :error, :raw_response, keyword_init: true
    SearchSecuritiesResponse = Struct.new :securities, :success?, :error, :raw_response, keyword_init: true
    SecurityInfoResponse = Struct.new :info, :success?, :error, :raw_response, keyword_init: true

    def base_url
      ENV["SYNTH_URL"] || "https://api.synthfinance.com"
    end

    def app_name
      "maybe_app"
    end

    def app_type
      Rails.application.config.app_mode
    end

    def client
      @client ||= Faraday.new(url: base_url) do |faraday|
        faraday.headers["Authorization"] = "Bearer #{api_key}"
        faraday.headers["X-Source"] = app_name
        faraday.headers["X-Source-Type"] = app_type
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
        req.headers["Authorization"] = "Bearer #{api_key}"
        params.each { |k, v| req.params[k.to_s] = v.to_s }
        req.params["page"] = page
      end
    end

    def paginate(url, params = {})
      results = []
      page = 1
      current_page = 0
      total_pages = 1

      while current_page < total_pages
        response = fetch_page(url, page, params)

        if response.success?
          body = JSON.parse(response.body)
          page_results = yield(body)
          results.concat(page_results)

          current_page = body.dig("paging", "current_page")
          total_pages = body.dig("paging", "total_pages")

          page += 1
        else
          raise build_error(response)
        end
      end

      results
    end
end
