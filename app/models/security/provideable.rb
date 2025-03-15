module Security::Provideable
  extend ActiveSupport::Concern

  Search = Data.define(:securities)
  PriceData = Data.define(:price)
  PricesData = Data.define(:prices)
  SecurityInfo = Data.define(
    :ticker,
    :name,
    :links,
    :logo_url,
    :description,
    :kind,
  )

  def search_securities(symbol, country_code: nil, exchange_operating_mic: nil)
    raise NotImplementedError, "Subclasses must implement #search_securities"
  end

  def fetch_security_info(ticker:, mic_code: nil, operating_mic: nil)
    raise NotImplementedError, "Subclasses must implement #fetch_security_info"
  end

  def fetch_security_price(ticker:, date:)
    raise NotImplementedError, "Subclasses must implement #fetch_security_price"
  end

  def fetch_security_prices(ticker:, start_date:, end_date:)
    raise NotImplementedError, "Subclasses must implement #fetch_security_prices"
  end
end
