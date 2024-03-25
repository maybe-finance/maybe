require "test_helper"

module MerchantDataProviderInterfaceTest
  def test_exchange_rate_provider_interface
    assert_respond_to @subject, :fetch_merchant_data
  end

  def test_exchange_rate_provider_response_contract
    accounting_for_http_providers do
      result = @subject.fetch_merchant_data(description: "AMZN Mktp US*RW1VY1ZU5")

      assert_respond_to result, :name
      assert_respond_to result, :website
      assert_respond_to result, :logo_url
    end
  rescue Provider::Base::UnsupportedOperationError
    # raising this error is also acceptable
  end

  private
    def accounting_for_http_providers
      VCR.use_cassette("synth_merchant_data") do
        yield
      end
    end
end
