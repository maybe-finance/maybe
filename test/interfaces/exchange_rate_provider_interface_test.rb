require "test_helper"

module ExchangeRateProviderInterfaceTest
  def test_exchange_rate_provider_interface
    assert_respond_to @subject, :fetch_exchange_rate
  end

  def test_exchange_rate_provider_response_contract
    accounting_for_http_providers do
      assert_respond_to @subject.fetch_exchange_rate(from: "USD", to: "MXN", date: Date.current), :rate
    end
  rescue Provider::Base::UnsupportedOperationError
    # raising this error is also acceptable
  end

  private
    def accounting_for_http_providers
      VCR.use_cassette("synth_exchange_rate") do
        yield
      end
    end
end
