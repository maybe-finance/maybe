require "test_helper"

module ExchangeRateProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "exchange rate provider interface" do
    assert_respond_to @subject, :fetch_exchange_rate
  end

  test "exchange rate provider response contract" do
    VCR.use_cassette "synth/exchange_rate" do
      response = @subject.fetch_exchange_rate from: "USD", to: "MXN", date: Date.current

      assert_respond_to response, :rate
      assert_respond_to response, :success?
      assert_respond_to response, :error
      assert_respond_to response, :raw_response
    end
  end
end
