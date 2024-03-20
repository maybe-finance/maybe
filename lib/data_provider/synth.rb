class DataProvider::Synth
    include DataProvider::ExchangeRate::Provideable

    BASE_URL = "https://api.synthfinance.com"

    def initialize(api_key)
        @api_key = api_key
    end

    def exchange_rate(from_currency, to_currency, date)
        response = Faraday.get("#{BASE_URL}/rates/historical") do |req|
            req.headers["Authorization"] = "Bearer #{@api_key}"
            req.params["from"] = from_currency
            req.params["to"] = to_currency
            req.params["date"] = date
        end
        data = JSON.parse(response.body)
        data.dig("data", "rates", to_currency)
    rescue StandardError
        nil
    end
end
