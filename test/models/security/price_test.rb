require "test_helper"
require "ostruct"

class Security::PriceTest < ActiveSupport::TestCase
  setup do
    @provider = mock

    Security::Price.stubs(:security_prices_provider).returns(@provider)
  end

  test "security price provider nil if no api key provided" do
    Security::Price.unstub(:security_prices_provider)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_not Security::Price.security_prices_provider
    end
  end

  test "finds single security price in DB" do
    @provider.expects(:fetch_security_prices).never

    price = security_prices(:one)

    assert_equal price, Security::Price.find_price(ticker: price.ticker, date: price.date)
  end

  test "caches prices to DB" do
    expected_price = 314.34
    @provider.expects(:fetch_security_prices)
             .once
             .returns(
               OpenStruct.new(
                 success?: true,
                 prices: [ { date: Date.current, price: expected_price } ]
               )
             )

    fetched_rate = Security::Price.find_price(ticker: "NVDA", date: Date.current, cache: true)
    refetched_rate = Security::Price.find_price(ticker: "NVDA", date: Date.current, cache: true)

    assert_equal expected_price, fetched_rate.price
    assert_equal expected_price, refetched_rate.price
  end

  test "returns nil if no price found in DB or from provider" do
    @provider.expects(:fetch_security_prices)
             .with(ticker: "NVDA", start_date: Date.current, end_date: Date.current)
             .once
             .returns(OpenStruct.new(success?: false))

    assert_not Security::Price.find_price(ticker: "NVDA", date: Date.current)
  end

  test "returns nil if price not found in DB and provider disabled" do
    Security::Price.unstub(:security_prices_provider)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_not Security::Price.find_price(ticker: "NVDA", date: Date.current)
    end
  end

  test "fetches multiple dates at once" do
    @provider.expects(:fetch_security_prices).never

    price1 = security_prices(:one) # AAPL today
    price2 = security_prices(:two) # AAPL yesterday

    fetched_prices = Security::Price.find_prices(start_date: 1.day.ago.to_date, end_date: Date.current, ticker: "AAPL").sort_by(&:date)

    assert_equal price1, fetched_prices[1]
    assert_equal price2, fetched_prices[0]
  end

  test "caches multiple prices to DB" do
    missing_price = 213.21
    @provider.expects(:fetch_security_prices)
             .with(ticker: "AAPL", start_date: 2.days.ago.to_date, end_date: 2.days.ago.to_date)
             .returns(OpenStruct.new(success?: true, prices: [ { date: 2.days.ago.to_date, price: missing_price } ]))
             .once

    price1 = security_prices(:one) # AAPL today
    price2 = security_prices(:two) # AAPL yesterday

    fetched_prices = Security::Price.find_prices(ticker: "AAPL", start_date: 2.days.ago.to_date, end_date: Date.current, cache: true)
    refetched_prices = Security::Price.find_prices(ticker: "AAPL", start_date: 2.days.ago.to_date, end_date: Date.current, cache: true)

    assert_equal [ missing_price, price2.price, price1.price ], fetched_prices.sort_by(&:date).map(&:price)
    assert_equal [ missing_price, price2.price, price1.price ], refetched_prices.sort_by(&:date).map(&:price)
  end

  test "returns empty array if no prices found in DB or from provider" do
    Security::Price.unstub(:security_prices_provider)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_equal [], Security::Price.find_prices(ticker: "NVDA", start_date: 10.days.ago.to_date, end_date: Date.current)
    end
  end

  test "uses locf gapfilling for weekends when price is missing" do
    friday = Date.new(2024, 10, 4) # A known Friday
    saturday = friday + 1.day # weekend
    sunday = saturday + 1.day # weekend
    monday = sunday + 1.day # known Monday

    Security::Price.create!(ticker: "TM", date: friday, price: 100)
    Security::Price.create!(ticker: "TM", date: monday, price: 110)

    # Data provider doesn't return weekend prices
    @provider.expects(:fetch_security_prices)
             .with(ticker: "TM", start_date: saturday, end_date: sunday)
             .returns(OpenStruct.new(success?: false))
             .once

    expected_prices = [
      Security::Price.new(ticker: "TM", date: friday, price: 100).price,
      Security::Price.new(ticker: "TM", date: saturday, price: 100).price,
      Security::Price.new(ticker: "TM", date: sunday, price: 100).price,
      Security::Price.new(ticker: "TM", date: monday, price: 110).price
    ]

    assert_equal expected_prices, Security::Price.find_prices(ticker: "TM", start_date: friday, end_date: monday).map(&:price)
  end
end
