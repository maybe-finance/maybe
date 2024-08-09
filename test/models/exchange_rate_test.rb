require "test_helper"
require "ostruct"

class ExchangeRateTest < ActiveSupport::TestCase
  setup do
    @provider = mock

    ExchangeRate.stubs(:exchange_rates_provider).returns(@provider)
  end

  test "exchange rate provider nil if no api key configured" do
    ExchangeRate.unstub(:exchange_rates_provider)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_not ExchangeRate.exchange_rates_provider
    end
  end

  test "finds single rate in DB" do
    @provider.expects(:fetch_exchange_rate).never

    rate = exchange_rates(:one)

    assert_equal rate, ExchangeRate.find_rate(from: rate.from_currency, to: rate.to_currency, date: rate.date)
  end

  test "finds single rate from provider and caches to DB" do
    expected_rate = 1.21
    @provider.expects(:fetch_exchange_rate).once.returns(OpenStruct.new(success?: true, rate: expected_rate))

    fetched_rate = ExchangeRate.find_rate(from: "USD", to: "EUR", date: Date.current, cache: true)
    refetched_rate = ExchangeRate.find_rate(from: "USD", to: "EUR", date: Date.current, cache: true)

    assert_equal expected_rate, fetched_rate.rate
    assert_equal expected_rate, refetched_rate.rate
  end

  test "nil if rate is not found in DB and provider throws an error" do
    @provider.expects(:fetch_exchange_rate).with(from: "USD", to: "EUR", date: Date.current).once.returns(OpenStruct.new(success?: false))

    assert_not ExchangeRate.find_rate(from: "USD", to: "EUR", date: Date.current)
  end

  test "nil if rate is not found in DB and provider is disabled" do
    ExchangeRate.unstub(:exchange_rates_provider)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_not ExchangeRate.find_rate(from: "USD", to: "EUR", date: Date.current)
    end
  end

  test "finds multiple rates in DB" do
    @provider.expects(:fetch_exchange_rate).never

    rate1 = exchange_rates(:one) # EUR -> GBP, today
    rate2 = exchange_rates(:two) # EUR -> GBP, yesterday

    fetched_rates = ExchangeRate.find_rates(from: rate1.from_currency, to: rate1.to_currency, start_date: 1.day.ago.to_date).sort_by(&:date)

    assert_equal rate1, fetched_rates[1]
    assert_equal rate2, fetched_rates[0]
  end

  test "finds multiple rates from provider and caches to DB" do
    @provider.expects(:fetch_exchange_rates).with(from: "EUR", to: "USD", date_start: 1.day.ago.to_date, date_end: Date.current)
      .returns(
        OpenStruct.new(
          rates: [
            OpenStruct.new(date: 1.day.ago.to_date, rate: 1.1),
            OpenStruct.new(date: Date.current, rate: 1.2)
          ],
          success?: true
        )
      ).once

    fetched_rates = ExchangeRate.find_rates(from: "EUR", to: "USD", start_date: 1.day.ago.to_date, cache: true)
    refetched_rates = ExchangeRate.find_rates(from: "EUR", to: "USD", start_date: 1.day.ago.to_date)

    assert_equal [ 1.1, 1.2 ], fetched_rates.sort_by(&:date).map(&:rate)
    assert_equal [ 1.1, 1.2 ], refetched_rates.sort_by(&:date).map(&:rate)
  end

  test "finds missing db rates from provider and appends to results" do
    @provider.expects(:fetch_exchange_rates).with(from: "EUR", to: "GBP", date_start: 2.days.ago.to_date, date_end: 2.days.ago.to_date)
      .returns(
        OpenStruct.new(
          rates: [
            OpenStruct.new(date: 2.day.ago.to_date, rate: 1.1)
          ],
          success?: true
        )
      ).once

    rate1 = exchange_rates(:one) # EUR -> GBP, today
    rate2 = exchange_rates(:two) # EUR -> GBP, yesterday

    fetched_rates = ExchangeRate.find_rates(from: "EUR", to: "GBP", start_date: 2.days.ago.to_date, cache: true)
    refetched_rates = ExchangeRate.find_rates(from: "EUR", to: "GBP", start_date: 2.days.ago.to_date)

    assert_equal [ 1.1, rate2.rate, rate1.rate ], fetched_rates.sort_by(&:date).map(&:rate)
    assert_equal [ 1.1, rate2.rate, rate1.rate ], refetched_rates.sort_by(&:date).map(&:rate)
  end

  test "returns empty array if no rates found in DB or provider" do
    ExchangeRate.unstub(:exchange_rates_provider)

    with_env_overrides SYNTH_API_KEY: nil do
      assert_equal [], ExchangeRate.find_rates(from: "USD", to: "JPY", start_date: 10.days.ago.to_date)
    end
  end
end
