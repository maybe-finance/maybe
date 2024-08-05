require "test_helper"
require "ostruct"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest, SecurityPriceProviderInterfaceTest

  setup do
    @subject = @synth = Provider::Synth.new(ENV["SYNTH_API_KEY"])
  end

  test "fetches paginated securities prices" do
    VCR.use_cassette("synth/security_prices") do
      response = @synth.fetch_security_prices ticker: "AAPL", start_date: Date.iso8601("2024-01-01"), end_date: Date.iso8601("2024-08-01")

      assert 213, response.size
    end
  end

  test "retries then provides failed response" do
    @client = mock
    Faraday.stubs(:new).returns(@client)

    @client.expects(:get).returns(OpenStruct.new(success?: false)).times(3)

    response = @synth.fetch_exchange_rate from: "USD", to: "MXN", date: Date.iso8601("2024-08-01")

    assert_match "Failed to fetch data from Provider::Synth", response.error.message
  end

  test "retrying, then raising on network error" do
    @client = mock
    Faraday.stubs(:new).returns(@client)

    @client.expects(:get).raises(Faraday::TimeoutError).times(3)

    assert_raises Faraday::TimeoutError do
      @synth.fetch_exchange_rate from: "USD", to: "MXN", date: Date.iso8601("2024-08-01")
    end
  end
end
