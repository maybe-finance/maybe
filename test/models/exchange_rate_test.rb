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

  test "retrying, then raising on provider error" do
    Faraday.expects(:get).returns(OpenStruct.new(success?: false)).times(3)

    error = assert_raises Provider::Base::ProviderError do
      ExchangeRate.find_rate_or_fetch from: "USD", to: "MXN", date: Date.current
    end

    assert_match "Failed to fetch exchange rate from Provider::Synth", error.message
  end

  test "retrying, then raising on network error" do
    Faraday.expects(:get).raises(Faraday::TimeoutError).times(3)

    assert_raises Faraday::TimeoutError do
      ExchangeRate.find_rate_or_fetch from: "USD", to: "MXN", date: Date.current
    end
  end
end
