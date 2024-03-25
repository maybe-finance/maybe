require "test_helper"

class Provided::ExchangeRateTest < ActiveSupport::TestCase
  test "fetch rate" do
    VCR.use_cassette("synth_exchange_rate") do
      assert_instance_of ExchangeRate,
        Provided::ExchangeRate.new.fetch_exchange_rate(from: "USD", to: "MXN", date: Date.parse("2024-03-24"))
    end
  end

  test "synth is used by default" do
    VCR.use_cassette("synth_exchange_rate") do
      Provider::Synth.any_instance.expects(:fetch_exchange_rate).with(from: "USD", to: "MXN", date: Date.parse("2024-03-24")).returns(OpenStruct.new(rate: 1.0))
      Provided::ExchangeRate.new.fetch_exchange_rate(from: "USD", to: "MXN", date: Date.parse("2024-03-24"))
    end
  end

  test "can be configured to use a different provider" do
    swap_provider_for :exchange_rates, to: :null do
      Provider::Null.any_instance.expects(:fetch_exchange_rate).with(from: "USD", to: "MXN", date: Date.parse("2024-03-24")).returns(OpenStruct.new(rate: 1.0))
      Provided::ExchangeRate.new.fetch_exchange_rate(from: "USD", to: "MXN", date: Date.parse("2024-03-24"))
    end
  end

  test "retrying, then raising on provider error" do
    Provider::Synth.any_instance
      .expects(:fetch_exchange_rate)
      .raises(Provider::Base::ProviderError)
      .times(3)

    assert_raises(Provider::Base::ProviderError, "error message") do
      ExchangeRate.get_rate("USD", "MXN", Date.parse("2024-03-24"))
    end
  end

  test "retrying, then raising on network error" do
    Faraday.expects(:get).raises(Faraday::TimeoutError).times(3)

    assert_raises(Faraday::TimeoutError, "error message") do
      ExchangeRate.get_rate("USD", "MXN", Date.parse("2024-03-24"))
    end
  end
end
