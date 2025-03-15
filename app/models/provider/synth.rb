class Provider::Synth < Provider
  include ExchangeRate::Provideable
  include Security::Provideable
  include Account::Transaction::Provideable

  def initialize(api_key)
    @api_key = api_key
  end

  def healthy?
    provider_response do
      response = client.get("#{base_url}/user")
      JSON.parse(response.body).dig("id").present?
    end
  end

  def usage
    provider_response do
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

  def fetch_security_prices(ticker:, start_date:, end_date:, operating_mic_code: nil)
    provider_response retries: 1 do
      params = {
        start_date: start_date,
        end_date: end_date
      }

      params[:operating_mic_code] = operating_mic_code if operating_mic_code.present?

      data = paginate(
        "#{base_url}/tickers/#{ticker}/open-close",
        params
      ) do |body|
        body.dig("prices")
      end

      currency = data.first_page.dig("currency")
      country_code = data.first_page.dig("exchange", "country_code")
      exchange_mic = data.first_page.dig("exchange", "mic_code")
      exchange_operating_mic = data.first_page.dig("exchange", "operating_mic_code")

      Security::Provideable::PricesData.new(
        prices: data.paginated.map do |price|
          Security::Price.new(
            security: Security.new(
              ticker: ticker,
              country_code: country_code,
              exchange_mic: exchange_mic,
              exchange_operating_mic: exchange_operating_mic
            ),
            date: price.dig("date"),
            price: price.dig("close") || price.dig("open"),
            currency: currency
          )
        end
      )
    end
  end

  def fetch_exchange_rate(from:, to:, date:)
    provider_response retries: 2 do
      response = client.get("#{base_url}/rates/historical") do |req|
        req.params["date"] = date.to_s
        req.params["from"] = from
        req.params["to"] = to
      end

      rates = JSON.parse(response.body).dig("data", "rates")

      ExchangeRate::Provideable::FetchRateData.new(
        rate: ExchangeRate.new(
          from_currency: from,
          to_currency: to,
          date: date,
          rate: rates.dig(to)
        )
      )
    end
  end

  def fetch_exchange_rates(from:, to:, start_date:, end_date:)
    provider_response retries: 1 do
      data = paginate(
        "#{base_url}/rates/historical-range",
        from: from,
        to: to,
        date_start: start_date.to_s,
        date_end: end_date.to_s
      ) do |body|
        body.dig("data")
      end

      ExchangeRate::Provideable::FetchRatesData.new(
        rates: data.paginated.map do |exchange_rate|
          ExchangeRate.new(
            from_currency: from,
            to_currency: to,
            date: exchange_rate.dig("date"),
            rate: exchange_rate.dig("rates", to)
          )
        end
      )
    end
  end

  def search_securities(symbol, country_code: nil, exchange_operating_mic: nil)
    return Security::Provideable::Search.new(securities: []) if symbol.blank? || symbol.length < 2

    provider_response do
      response = client.get("#{base_url}/tickers/search") do |req|
        req.params["name"] = symbol
        req.params["dataset"] = "limited"
        req.params["country_code"] = country_code if country_code.present?
        req.params["exchange_operating_mic"] = exchange_operating_mic if exchange_operating_mic.present?
        req.params["limit"] = 25
      end

      parsed = JSON.parse(response.body)

      Security::Provideable::Search.new(
        securities: parsed.dig("data").map do |security|
          Security.new(
            ticker: security.dig("symbol"),
            name: security.dig("name"),
            logo_url: security.dig("logo_url"),
            exchange_acronym: security.dig("exchange", "acronym"),
            exchange_mic: security.dig("exchange", "mic_code"),
            exchange_operating_mic: security.dig("exchange", "operating_mic_code"),
            country_code: security.dig("exchange", "country_code")
          )
        end
      )
    end
  end

  def fetch_security_info(ticker:, mic_code: nil, operating_mic: nil)
    provider_response do
      response = client.get("#{base_url}/tickers/#{ticker}") do |req|
        req.params["mic_code"] = mic_code if mic_code.present?
        req.params["operating_mic"] = operating_mic if operating_mic.present?
      end

      data = JSON.parse(response.body).dig("data")

      Security::Provideable::SecurityInfo.new(
        ticker: ticker,
        name: data.dig("name"),
        links: data.dig("links"),
        logo_url: data.dig("logo_url"),
        description: data.dig("description"),
        kind: data.dig("kind")
      )
    end
  end

  def enrich_transaction(description, amount: nil, date: nil, city: nil, state: nil, country: nil)
    provider_response do
      params = {
        description: description,
        amount: amount,
        date: date,
        city: city,
        state: state,
        country: country
      }.compact

      response = client.get("#{base_url}/enrich", params)

      parsed = JSON.parse(response.body)

      TransactionEnrichmentData.new(
        name: parsed.dig("merchant"),
        icon_url: parsed.dig("icon"),
        category: parsed.dig("category")
      )
    end
  end

  private
    attr_reader :api_key

    TransactionEnrichmentData = Data.define(:name, :icon_url, :category)

    def retryable_errors
      [
        Faraday::TimeoutError,
        Faraday::ConnectionFailed,
        Faraday::SSLError,
        Faraday::ClientError,
        Faraday::ServerError
      ]
    end

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
