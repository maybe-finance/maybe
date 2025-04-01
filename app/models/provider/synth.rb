class Provider::Synth < Provider
  include ExchangeRateConcept, SecurityConcept

  # Subclass so errors caught in this provider are raised as Provider::Synth::Error
  Error = Class.new(Provider::Error)

  def initialize(api_key)
    @api_key = api_key
  end

  def healthy?
    with_provider_response do
      response = client.get("#{base_url}/user")
      JSON.parse(response.body).dig("id").present?
    end
  end

  def usage
    with_provider_response do
      response = client.get("#{base_url}/user")

      parsed = JSON.parse(response.body)

      remaining = parsed.dig("api_calls_remaining")
      limit = parsed.dig("api_limit")
      used = limit - remaining

      UsageData.new(
        used: used,
        limit: limit,
        utilization: used.to_f / limit * 100,
        plan: parsed.dig("plan"),
      )
    end
  end

  # ================================
  #          Exchange Rates
  # ================================

  def fetch_exchange_rate(from:, to:, date:)
    with_provider_response do
      response = client.get("#{base_url}/rates/historical") do |req|
        req.params["date"] = date.to_s
        req.params["from"] = from
        req.params["to"] = to
      end

      rates = JSON.parse(response.body).dig("data", "rates")

      Rate.new(date:, from:, to:, rate: rates.dig(to))
    end
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    with_provider_response do
      data = paginate(
        "#{base_url}/rates/historical-range",
        from: from,
        to: to,
        date_start: start_date.to_s,
        date_end: end_date.to_s
      ) do |body|
        body.dig("data")
      end

      data.paginated.map do |rate|
        Rate.new(date: rate.dig("date"), from:, to:, rate: rate.dig("rates", to))
      end
    end
  end

  # ================================
  #           Securities
  # ================================

  def search_securities(symbol, country_code: nil, exchange_operating_mic: nil)
    with_provider_response do
      response = client.get("#{base_url}/tickers/search") do |req|
        req.params["name"] = symbol
        req.params["dataset"] = "limited"
        req.params["country_code"] = country_code if country_code.present?
        req.params["exchange_operating_mic"] = exchange_operating_mic if exchange_operating_mic.present?
        req.params["limit"] = 25
      end

      parsed = JSON.parse(response.body)

      parsed.dig("data").map do |security|
        Security.new(
          symbol: security.dig("symbol"),
          name: security.dig("name"),
          logo_url: security.dig("logo_url"),
          exchange_operating_mic: security.dig("exchange", "operating_mic_code"),
        )
      end
    end
  end

  def fetch_security_info(security)
    with_provider_response do
      response = client.get("#{base_url}/tickers/#{security.ticker}") do |req|
        req.params["mic_code"] = security.exchange_mic if security.exchange_mic.present?
        req.params["operating_mic"] = security.exchange_operating_mic if security.exchange_operating_mic.present?
      end

      data = JSON.parse(response.body).dig("data")

      SecurityInfo.new(
        symbol: data.dig("ticker"),
        name: data.dig("name"),
        links: data.dig("links"),
        logo_url: data.dig("logo_url"),
        description: data.dig("description"),
        kind: data.dig("kind")
      )
    end
  end

  def fetch_security_price(security, date:)
    with_provider_response do
      historical_data = fetch_security_prices(security, start_date: date, end_date: date)

      raise ProviderError, "No prices found for security #{security.ticker} on date #{date}" if historical_data.data.empty?

      historical_data.data.first
    end
  end

  def fetch_security_prices(security, start_date:, end_date:)
    with_provider_response do
      params = {
        start_date: start_date,
        end_date: end_date
      }

      params[:operating_mic_code] = security.exchange_operating_mic if security.exchange_operating_mic.present?

      data = paginate(
        "#{base_url}/tickers/#{security.ticker}/open-close",
        params
      ) do |body|
        body.dig("prices")
      end

      currency = data.first_page.dig("currency")
      country_code = data.first_page.dig("exchange", "country_code")
      exchange_mic = data.first_page.dig("exchange", "mic_code")
      exchange_operating_mic = data.first_page.dig("exchange", "operating_mic_code")

      data.paginated.map do |price|
        Price.new(
          security: security,
          date: price.dig("date"),
          price: price.dig("close") || price.dig("open"),
          currency: currency
        )
      end
    end
  end

  private
    attr_reader :api_key

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
        faraday.request(:retry, {
          max: 2,
          interval: 0.05,
          interval_randomness: 0.5,
          backoff_factor: 2
        })

        faraday.response :raise_error
        faraday.headers["Authorization"] = "Bearer #{api_key}"
        faraday.headers["X-Source"] = app_name
        faraday.headers["X-Source-Type"] = app_type
      end
    end

    def fetch_page(url, page, params = {})
      client.get(url, params.merge(page: page))
    end

    def paginate(url, params = {})
      results = []
      page = 1
      current_page = 0
      total_pages = 1
      first_page = nil

      while current_page < total_pages
        response = fetch_page(url, page, params)

        body = JSON.parse(response.body)
        first_page = body unless first_page
        page_results = yield(body)
        results.concat(page_results)

        current_page = body.dig("paging", "current_page")
        total_pages = body.dig("paging", "total_pages")

        page += 1
      end

      PaginatedData.new(
        paginated: results,
        first_page: first_page,
        total_pages: total_pages
      )
    end
end
