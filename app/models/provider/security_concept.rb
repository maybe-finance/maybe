module Provider::SecurityConcept
  extend ActiveSupport::Concern

  Security = Data.define(:symbol, :name, :logo_url, :exchange_operating_mic)
  SecurityInfo = Data.define(:symbol, :name, :links, :logo_url, :description, :kind)
  Price = Data.define(:security, :date, :price, :currency)

  def search_securities(symbol, country_code: nil, exchange_operating_mic: nil)
    raise NotImplementedError, "Subclasses must implement #search_securities"
  end

  def fetch_security_info(security)
    raise NotImplementedError, "Subclasses must implement #fetch_security_info"
  end

  def fetch_security_price(security, date:)
    raise NotImplementedError, "Subclasses must implement #fetch_security_price"
  end

  def fetch_security_prices(security, start_date:, end_date:)
    raise NotImplementedError, "Subclasses must implement #fetch_security_prices"
  end
end
