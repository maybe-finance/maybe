module SecuritiesTestHelper
  def create_security(symbol, prices:)
    isin_codes = {
      "AMZN" => "US0231351067",
      "NVDA" => "US67066G1040"
    }

    isin = isin_codes[symbol]

    prices.each do |price|
      Security::Price.create! isin: isin, date: price[:date], price: price[:price]
    end

    Security.create! isin: isin, symbol: symbol
  end
end
