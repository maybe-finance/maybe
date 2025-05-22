class Provider::Synth < Provider
  include ExchangeRateConcept, SecurityConcept

  # Subclass so errors caught in this provider are raised as Provider::Synth::Error
  Error = Class.new(Provider::Error)
  InvalidExchangeRateError = Class.new(Error)
  InvalidSecurityPriceError = Class.new(Error)

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

      Rate.new(date: date.to_date, from:, to:, rate: rates.dig(to))
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
        date = rate.dig("date")
        rate = rate.dig("rates", to)

        if date.nil? || rate.nil?
          Rails.logger.warn("#{self.class.name} returned invalid rate data for pair from: #{from} to: #{to} on: #{date}.  Rate data: #{rate.inspect}")
          Sentry.capture_exception(InvalidExchangeRateError.new("#{self.class.name} returned invalid rate data"), level: :warning) do |scope|
            scope.set_context("rate", { from: from, to: to, date: date })
          end

          next
        end

        Rate.new(date: date.to_date, from:, to:, rate:)
      end.compact
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
        # Synth uses mic_code, which encompasses both exchange_mic AND exchange_operating_mic (union)
        req.params["mic_code"] = exchange_operating_mic if exchange_operating_mic.present?
        req.params["limit"] = 25
      end

      parsed = JSON.parse(response.body)

      parsed.dig("data").map do |security|
        Security.new(
          symbol: security.dig("symbol"),
          name: security.dig("name"),
          logo_url: security.dig("logo_url"),
          exchange_operating_mic: security.dig("exchange", "operating_mic_code"),
          country_code: security.dig("exchange", "country_code")
        )
      end
    end
  end

  def fetch_security_info(symbol:, exchange_operating_mic:)
    with_provider_response do
      response = client.get("#{base_url}/tickers/#{symbol}") do |req|
        req.params["operating_mic"] = exchange_operating_mic
      end

      data = JSON.parse(response.body).dig("data")

      SecurityInfo.new(
        symbol: symbol,
        name: data.dig("name"),
        links: data.dig("links"),
        logo_url: data.dig("logo_url"),
        description: data.dig("description"),
        kind: data.dig("kind"),
        exchange_operating_mic: exchange_operating_mic
      )
    end
  end

  def fetch_security_price(symbol:, exchange_operating_mic: nil, date:)
    with_provider_response do
      historical_data = fetch_security_prices(symbol:, exchange_operating_mic:, start_date: date, end_date: date)

      raise ProviderError, "No prices found for security #{symbol} on date #{date}" if historical_data.data.empty?

      historical_data.data.first
    end
  end

  def fetch_security_prices(symbol:, exchange_operating_mic: nil, start_date:, end_date:)
    with_provider_response do
      params = {
        start_date: start_date,
        end_date: end_date,
        operating_mic_code: exchange_operating_mic
      }.compact

      data = paginate(
        "#{base_url}/tickers/#{symbol}/open-close",
        params
      ) do |body|
        body.dig("prices")
      end

      currency = data.first_page.dig("currency")
      exchange_operating_mic = data.first_page.dig("exchange", "operating_mic_code")

      data.paginated.map do |price|
        date = price.dig("date")
        price = price.dig("close") || price.dig("open")

        if date.nil? || price.nil?
          Rails.logger.warn("#{self.class.name} returned invalid price data for security #{symbol} on: #{date}.  Price data: #{price.inspect}")
          Sentry.capture_exception(InvalidSecurityPriceError.new("#{self.class.name} returned invalid security price data"), level: :warning) do |scope|
            scope.set_context("security", { symbol: symbol, date: date })
          end

          next
        end

        Price.new(
          symbol: symbol,
          date: date.to_date,
          price: price,
          currency: currency,
          exchange_operating_mic: exchange_operating_mic
        )
      end.compact
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
