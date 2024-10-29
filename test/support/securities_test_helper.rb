module SecuritiesTestHelper
  def create_security(ticker, prices:)
    security = Security.create!(
      ticker: ticker,
      exchange_mic: "XNAS"
    )

    prices.each do |price|
      Security::Price.create!(
        security: security,
        date: price[:date],
        price: price[:price],
        currency: "USD"
      )
    end

    security
  end
end
