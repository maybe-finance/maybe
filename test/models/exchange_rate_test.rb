require "test_helper"

class ExchangeRateTest < ActiveSupport::TestCase
  test "find rate in db" do
    assert_equal exchange_rates(:day_29_ago_eur_to_usd),
      ExchangeRate.find_rate_or_fetch(from: "EUR", to: "USD", date: 29.days.ago.to_date)
  end

  test "fetch rate from provider when it's not found in db" do
    ExchangeRate
      .expects(:fetch_rate_from_provider)
      .returns(ExchangeRate.new(base_currency: "USD", converted_currency: "MXN", rate: 1.0, date: Date.current))

    ExchangeRate.find_rate_or_fetch from: "USD", to: "MXN", date: Date.current
  end

  test "provided rates are saved to the db" do
    VCR.use_cassette("synth_exchange_rate") do
      assert_difference "ExchangeRate.count", 1 do
        ExchangeRate.find_rate_or_fetch from: "USD", to: "MXN", date: Date.current
      end
    end
  end

  test "fetch rate" do
    VCR.use_cassette("synth_exchange_rate") do
      assert_instance_of ExchangeRate,
        ExchangeRate.fetch_rate_from_provider(from: "USD", to: "MXN", date: Date.current)
    end
  end

  test "synth is used by default when fetching" do
    VCR.use_cassette("synth_exchange_rate") do
      Provider::Synth.any_instance.expects(:fetch_exchange_rate).with(from: "USD", to: "MXN", date: Date.current).returns(OpenStruct.new(rate: 1.0))
      ExchangeRate.fetch_rate_from_provider from: "USD", to: "MXN", date: Date.current
    end
  end

  test "can be configured to use a different provider" do
    swap_provider_for :exchange_rates, to: :null do
      Provider::Null.any_instance.expects(:fetch_exchange_rate).with(from: "USD", to: "MXN", date: Date.current).returns(OpenStruct.new(rate: 1.0))
      ExchangeRate.fetch_rate_from_provider from: "USD", to: "MXN", date: Date.current
    end
  end

  test "retrying, then raising on provider error" do
    Faraday.expects(:get).returns(OpenStruct.new(success?: false)).times(3)

    assert_nil ExchangeRate.fetch_rate_from_provider from: "USD", to: "MXN", date: Date.current
  end

  test "retrying, then raising on network error" do
    Faraday.expects(:get).raises(Faraday::TimeoutError).times(3)

    assert_raises Faraday::TimeoutError do
      ExchangeRate.fetch_rate_from_provider from: "USD", to: "MXN", date: Date.current
    end
  end
end
