require "test_helper"

module ExchangeRateProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "exchange rate provider interface" do
    assert_respond_to @subject, :fetch_exchange_rate
  end

  test "exchange rate provider response contract" do
    accounting_for_http_calls do
      response = @subject.fetch_exchange_rate from: "USD", to: "MXN", date: Date.current

      assert_respond_to response, :rate
      assert_respond_to response, :success?
      assert_respond_to response, :error
      assert_respond_to response, :raw_response
    end
  end

  private
    def accounting_for_http_calls
      VCR.use_cassette "synth_exchange_rate" do
        yield
      end
    end
end
