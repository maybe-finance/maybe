class Demo::SecurityGenerator
  include Demo::DataHelper

  def load_securities!(count: 6)
    if count <= 6
      create_standard_securities!(count)
    else
      securities = create_standard_securities!(6)
      securities.concat(create_performance_securities!(count - 6))
      securities
    end
  end

  def create_standard_securities!(count)
    securities_data = [
      { ticker: "AAPL", name: "Apple Inc.", exchange: "XNAS" },
      { ticker: "GOOGL", name: "Alphabet Inc.", exchange: "XNAS" },
      { ticker: "MSFT", name: "Microsoft Corporation", exchange: "XNAS" },
      { ticker: "AMZN", name: "Amazon.com Inc.", exchange: "XNAS" },
      { ticker: "TSLA", name: "Tesla Inc.", exchange: "XNAS" },
      { ticker: "NVDA", name: "NVIDIA Corporation", exchange: "XNAS" }
    ]

    securities = []
    count.times do |i|
      data = securities_data[i]
      security = create_security!(
        ticker: data[:ticker],
        name: data[:name],
        exchange_operating_mic: data[:exchange]
      )
      securities << security
    end
    securities
  end

  def create_performance_securities!(count)
    securities = []
    count.times do |i|
      security = create_security!(
        ticker: "SYM#{i + 7}",
        name: "Company #{i + 7}",
        exchange_operating_mic: "XNAS"
      )
      securities << security
    end
    securities
  end

  def create_security!(ticker:, name:, exchange_operating_mic:)
    security = Security.create!(ticker: ticker, name: name, exchange_operating_mic: exchange_operating_mic)
    create_price_history!(security)
    security
  end

  def create_price_history!(security, extended: false)
    days_back = extended ? 365 : 90
    price_base = 100.0
    prices = []

    (0..days_back).each do |i|
      date = i.days.ago.to_date
      price_change = (rand - 0.5) * 10
      price_base = [ price_base + price_change, 10.0 ].max

      price = security.prices.create!(
        date: date,
        price: price_base.round(2),
        currency: "USD"
      )
      prices << price
    end

    prices
  end
end
