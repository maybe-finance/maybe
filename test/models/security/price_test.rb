require "test_helper"
require "ostruct"

class Security::PriceTest < ActiveSupport::TestCase
  setup do
    @provider = mock

    Security::Price.stubs(:provider).returns(@provider)
  end

  test "security price provider nil if no api key provided" do
    Security::Price.unstub(:provider)

    Setting.stubs(:synth_api_key).returns(nil)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_not Security::Price.provider
    end
  end

  test "finds single security price in DB" do
    @provider.expects(:fetch_security_prices).never
    security = securities(:aapl)

    price = security_prices(:one)

    assert_equal price, Security::Price.find_price(security: security, date: price.date)
  end

  test "caches prices to DB" do
    expected_price = 314.34
    security = securities(:aapl)
    tomorrow = Date.current + 1.day

    @provider.expects(:fetch_security_prices)
            .with(ticker: security.ticker, mic_code: security.exchange_operating_mic, start_date: tomorrow, end_date: tomorrow)
            .once
            .returns(
              OpenStruct.new(
                success?: true,
                prices: [ { date: tomorrow, price: expected_price, currency: "USD" } ]
              )
            )

    fetched_rate = Security::Price.find_price(security: security, date: tomorrow, cache: true)
    refetched_rate = Security::Price.find_price(security: security, date: tomorrow, cache: true)

    assert_equal expected_price, fetched_rate.price
    assert_equal expected_price, refetched_rate.price
  end

  test "returns nil if no price found in DB or from provider" do
    security = securities(:aapl)
    Security::Price.delete_all # Clear any existing prices

    @provider.expects(:fetch_security_prices)
             .with(ticker: security.ticker, mic_code: security.exchange_operating_mic, start_date: Date.current, end_date: Date.current)
             .once
             .returns(OpenStruct.new(success?: false))

    assert_not Security::Price.find_price(security: security, date: Date.current)
  end

  test "returns nil if price not found in DB and provider disabled" do
    Security::Price.unstub(:provider)

    Setting.stubs(:synth_api_key).returns(nil)

    security = Security.new(ticker: "NVDA")

    with_env_overrides SYNTH_API_KEY: nil do
      assert_not Security::Price.find_price(security: security, date: Date.current)
    end
  end

  test "fetches multiple dates at once" do
    @provider.expects(:fetch_security_prices).never
    security = securities(:aapl)
    price1 = security_prices(:one) # AAPL today
    price2 = security_prices(:two) # AAPL yesterday

    fetched_prices = Security::Price.find_prices(security: security, start_date: 1.day.ago.to_date, end_date: Date.current).sort_by(&:date)

    assert_equal price1, fetched_prices[1]
    assert_equal price2, fetched_prices[0]
  end

  test "caches multiple prices to DB" do
    missing_price = 213.21
    security = securities(:aapl)

    @provider.expects(:fetch_security_prices)
             .with(ticker: security.ticker,
                  mic_code: security.exchange_operating_mic,
                  start_date: 2.days.ago.to_date,
                  end_date: 2.days.ago.to_date)
             .returns(OpenStruct.new(success?: true, prices: [ { date: 2.days.ago.to_date, price: missing_price, currency: "USD" } ]))
             .once

    price1 = security_prices(:one) # AAPL today
    price2 = security_prices(:two) # AAPL yesterday

    fetched_prices = Security::Price.find_prices(security: security, start_date: 2.days.ago.to_date, end_date: Date.current, cache: true)
    refetched_prices = Security::Price.find_prices(security: security, start_date: 2.days.ago.to_date, end_date: Date.current, cache: true)

    assert_equal [ missing_price, price2.price, price1.price ], fetched_prices.sort_by(&:date).map(&:price)
    assert_equal [ missing_price, price2.price, price1.price ], refetched_prices.sort_by(&:date).map(&:price)

    assert Security::Price.exists?(security: security, date: 2.days.ago.to_date, price: missing_price)
  end

  test "returns empty array if no prices found in DB or from provider" do
    Security::Price.unstub(:provider)

    Setting.stubs(:synth_api_key).returns(nil)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_equal [], Security::Price.find_prices(security: Security.new(ticker: "NVDA"), start_date: 10.days.ago.to_date, end_date: Date.current)
    end
  end
end
