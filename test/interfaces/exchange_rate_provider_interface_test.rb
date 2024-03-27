require "test_helper"

module ExchangeRateProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "exchange rate provider interface" do
    assert_respond_to @subject, :fetch_exchange_rate
  end

  test "exchange rate provider response contract" do
    accounting_for_http_calls do
      assert_respond_to @subject.fetch_exchange_rate(from: "USD", to: "MXN", date: Date.current), :rate
    end
  end

  private
    def accounting_for_http_calls
      VCR.use_cassette("synth_exchange_rate") do
        yield
      end
    end
end
