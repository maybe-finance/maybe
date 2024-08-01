module SecuritiesTestHelper
  def create_security(ticker, prices:)
    prices.each do |price|
      Security::Price.create! ticker: ticker, date: price[:date], price: price[:price]
    end

    Security.create! ticker: ticker
  end
end
