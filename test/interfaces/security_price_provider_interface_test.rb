require "test_helper"

module SecurityPriceProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "security price provider interface" do
    assert_respond_to @subject, :fetch_security_prices
  end

  test "security price provider response contract" do
    VCR.use_cassette "synth/security_prices" do
      response = @subject.fetch_security_prices ticker: "AAPL", start_date: Date.iso8601("2024-01-01"), end_date: Date.iso8601("2024-08-01")

      assert_respond_to response, :prices
      assert_respond_to response, :success?
      assert_respond_to response, :error
      assert_respond_to response, :raw_response
    end
  end
end
