require "test_helper"
require "ostruct"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest

  setup do
    @subject = Provider::Synth.new synth_api_key
  end

  test "retries then provides failed response" do
    Faraday.expects(:get).returns(OpenStruct.new(success?: false)).times(3)

    response = @subject.fetch_exchange_rate from: "USD", to: "MXN", date: Date.current

    assert_match "Failed to fetch exchange rate from Provider::Synth", response.error.message
  end

  test "retrying, then raising on network error" do
    Faraday.expects(:get).raises(Faraday::TimeoutError).times(3)

    assert_raises Faraday::TimeoutError do
      @subject.fetch_exchange_rate from: "USD", to: "MXN", date: Date.current
    end
  end
end
