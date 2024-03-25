require "test_helper"

module RealEstateValuationsProviderInterfaceTest
  def test_exchange_rate_provider_interface
    assert_respond_to @subject, :fetch_real_estate_valuation
  end

  def test_exchange_rate_provider_response_contract
    assert_respond_to @subject.fetch_real_estate_valuation(address: "123 main street"), :value
  rescue Provider::Base::UnsupportedOperationError
    # raising this error is also acceptable
  end
end
