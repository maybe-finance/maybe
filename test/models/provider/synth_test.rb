require "test_helper"
require "ostruct"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest, SecurityPriceProviderInterfaceTest

  setup do
    @subject = @synth = Provider::Synth.new(ENV["SYNTH_API_KEY"])
  end

  test "fetches paginated securities prices" do
    VCR.use_cassette("synth/security_prices") do
      response = @synth.fetch_security_prices(
        ticker: "AAPL",
        mic_code: "XNAS",
        start_date: Date.iso8601("2024-01-01"),
        end_date: Date.iso8601("2024-08-01")
      )

      puts response

      assert 213, response
    end
  end

  test "fetches paginated exchange_rate historical data" do
    VCR.use_cassette("synth/exchange_rate_historical") do
      response = @synth.fetch_exchange_rates(
        from: "USD", to: "GBP", start_date: Date.parse("01.01.2024"), end_date: Date.parse("31.07.2024")
      )

      assert 213, response.rates.size # 213 days between 01.01.2024 and 31.07.2024
      assert_equal [ :date, :rate ], response.rates.first.keys
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
