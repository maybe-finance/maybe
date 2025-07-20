# app/apps/investment_analytics/services/investment_analytics/fmp_provider.rb

module InvestmentAnalytics
  require Rails.root.join("app", "models", "provider")
  class FmpProvider < ::Provider

    BASE_URL = "https://financialmodelingprep.com/api/v3"

    def initialize(api_key: ENV['FMP_API_KEY'])
      raise ArgumentError, "FMP_API_KEY environment variable is not set" if api_key.blank?
      @api_key = api_key
    end

    # Fetches a stock quote
    # Docs: https://site.financialmodelingprep.com/developer/docs/#Stock-Price
    def quote(symbol)
      get("quote/#{symbol}").first
    end

    # Fetches historical prices
    # Docs: https://site.financialmodelingprep.com/developer/docs/#Historical-Stock-Prices
    def historical_prices(symbol, from_date: nil, to_date: nil)
      params = { from: from_date, to: to_date }.compact
      get("historical-price-full/#{symbol}", params: params)['historicalStockList']&.first&.dig('historical')
    end

    # Fetches historical dividend data
    # Docs: https://site.financialmodelingprep.com/developer/docs/#Stock-Historical-Dividend
    def historical_dividends(symbol)
      get("historical-dividends/#{symbol}")
    end

    private

    def get(path, params: {})
      response = HTTParty.get(
        "#{BASE_URL}/#{path}",
        query: params.merge(apikey: @api_key)
      )
      handle_response(response)
    end

    def handle_response(response)
      unless response.success?
        raise Provider::Error, "FMP API Error: #{response.code} - #{response.body}"
      end
      JSON.parse(response.body)
    rescue JSON::ParserError
      raise Provider::Error, "FMP API Error: Invalid JSON response"
    end
  end
end
