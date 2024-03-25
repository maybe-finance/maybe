require "test_helper"

module ExchangeRateProviderInterfaceTest
  def test_exchange_rate_provider_interface
    assert_respond_to @subject, :fetch_exchange_rate
    assert_respond_to @subject.fetch_exchange_rate(from: "USD", to: "MXN", date: Date.parse("2024-03-24")), :rate
  end
end
