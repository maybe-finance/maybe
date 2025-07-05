module ExchangeRateTestHelper
  def load_exchange_prices
    cad_rates = {
      4.days.ago.to_date => 1.36,
      3.days.ago.to_date => 1.37,
      2.days.ago.to_date => 1.38,
      1.day.ago.to_date  => 1.39,
      Date.current => 1.40
    }

    eur_rates = {
      4.days.ago.to_date => 1.17,
      3.days.ago.to_date => 1.18,
      2.days.ago.to_date => 1.19,
      1.day.ago.to_date  => 1.2,
      Date.current => 1.21
    }

    cad_rates.each do |date, rate|
      # USD to CAD
      ExchangeRate.create!(
        from_currency: "USD",
        to_currency: "CAD",
        date: date,
        rate: rate
      )

      # CAD to USD (inverse)
      ExchangeRate.create!(
        from_currency: "CAD",
        to_currency: "USD",
        date: date,
        rate: (1.0 / rate).round(6)
      )
    end

    eur_rates.each do |date, rate|
      # EUR to USD
      ExchangeRate.create!(
        from_currency: "EUR",
        to_currency: "USD",
        date: date,
        rate: rate
      )

      # USD to EUR (inverse)
      ExchangeRate.create!(
        from_currency: "USD",
        to_currency: "EUR",
        date: date,
        rate: (1.0 / rate).round(6)
      )
    end
  end
end
