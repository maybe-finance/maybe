require "test_helper"
require "ostruct"

class ExchangeRateTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    @provider = mock

    ExchangeRate.stubs(:provider).returns(@provider)
  end

  test "finds rate in DB" do
    existing_rate = exchange_rates(:one)

    @provider.expects(:fetch_exchange_rate).never

    assert_equal existing_rate, ExchangeRate.find_or_fetch_rate(
                                              from: existing_rate.from_currency,
                                              to: existing_rate.to_currency,
                                              date: existing_rate.date
                                            )
  end

  test "fetches rate from provider without cache" do
    ExchangeRate.delete_all

    provider_response = provider_success_response(
      OpenStruct.new(
        from: "USD",
        to: "EUR",
        date: Date.current,
        rate: 1.2
      )
    )

    @provider.expects(:fetch_exchange_rate).returns(provider_response)

    assert_no_difference "ExchangeRate.count" do
      assert_equal 1.2, ExchangeRate.find_or_fetch_rate(from: "USD", to: "EUR", date: Date.current, cache: false).rate
    end
  end

  test "fetches rate from provider with cache" do
    ExchangeRate.delete_all

    provider_response = provider_success_response(
      OpenStruct.new(
        from: "USD",
        to: "EUR",
        date: Date.current,
        rate: 1.2
      )
    )

    @provider.expects(:fetch_exchange_rate).returns(provider_response)

    assert_difference "ExchangeRate.count", 1 do
      assert_equal 1.2, ExchangeRate.find_or_fetch_rate(from: "USD", to: "EUR", date: Date.current, cache: true).rate
    end
  end

  test "returns nil on provider error" do
    provider_response = provider_error_response(StandardError.new("Test error"))

    @provider.expects(:fetch_exchange_rate).returns(provider_response)

    assert_nil ExchangeRate.find_or_fetch_rate(from: "USD", to: "EUR", date: Date.current, cache: true)
  end

  test "upserts rates for currency pair and date range" do
    ExchangeRate.delete_all

    ExchangeRate.create!(date: 1.day.ago.to_date, from_currency: "USD", to_currency: "EUR", rate: 0.9)

    provider_response = provider_success_response([
      OpenStruct.new(from: "USD", to: "EUR", date: Date.current, rate: 1.3),
      OpenStruct.new(from: "USD", to: "EUR", date: 1.day.ago.to_date, rate: 1.4),
      OpenStruct.new(from: "USD", to: "EUR", date: 2.days.ago.to_date, rate: 1.5)
    ])

    @provider.expects(:fetch_exchange_rates)
             .with(from: "USD", to: "EUR", start_date: 2.days.ago.to_date, end_date: Date.current)
             .returns(provider_response)

    ExchangeRate.sync_provider_rates(from: "USD", to: "EUR", start_date: 2.days.ago.to_date)

    assert_equal 1.3, ExchangeRate.find_by(from_currency: "USD", to_currency: "EUR", date: Date.current).rate
    assert_equal 1.4, ExchangeRate.find_by(from_currency: "USD", to_currency: "EUR", date: 1.day.ago.to_date).rate
    assert_equal 1.5, ExchangeRate.find_by(from_currency: "USD", to_currency: "EUR", date: 2.days.ago.to_date).rate
  end
end
