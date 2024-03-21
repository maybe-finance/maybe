class ExchangeRate < ApplicationRecord
  validates :base_currency, :converted_currency, presence: true

  class << self
    def convert(from, to, amount)
      rate = ExchangeRate.find_by(base_currency: from, converted_currency: to, date: Date.current)
      return nil if rate.nil?
      amount * rate.rate
    end

    def get_rate(from, to, date)
      _from = Money::Currency.new(from)
      _to = Money::Currency.new(to)
      find_by! base_currency: _from.iso_code, converted_currency: _to.iso_code, date: date
    rescue
      logger.warn "Exchange rate not found for #{_from.iso_code} to #{_to.iso_code} on #{date}"
      nil
    end

    def get_rate_series(from, to, date_range)
      where(base_currency: from, converted_currency: to, date: date_range).order(:date)
    end

    # TODO: Replace with generic provider
    # See https://github.com/maybe-finance/maybe/pull/556
    def fetch_rate_from_provider(from, to, date)
      response = Faraday.get("https://api.synthfinance.com/rates/historical") do |req|
        req.headers["Authorization"] = "Bearer #{ENV["SYNTH_API_KEY"]}"
        req.params["date"] = date.to_s
        req.params["from"] = from
        req.params["to"] = to
      end

      if response.success?
        rates = JSON.parse(response.body)
        rates.dig("data", "rates", to)
      else
        nil
      end
    end
  end
end
