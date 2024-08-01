require "test_helper"
require "ostruct"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest, SecurityPriceProviderInterfaceTest

  setup do
    @subject = @synth = Provider::Synth.new("fookey")
  end

  test "retries then provides failed response" do
    Faraday.expects(:get).returns(OpenStruct.new(success?: false)).times(3)

    response = @synth.fetch_exchange_rate from: "USD", to: "MXN", date: Date.current

    assert_match "Failed to fetch data from Provider::Synth", response.error.message
  end

  test "retrying, then raising on network error" do
    Faraday.expects(:get).raises(Faraday::TimeoutError).times(3)

    assert_raises Faraday::TimeoutError do
      @synth.fetch_exchange_rate from: "USD", to: "MXN", date: Date.current
    end
  end
end
