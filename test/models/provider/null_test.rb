require "test_helper"

class Provider::NullTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest
  include MerchantDataProviderInterfaceTest
  include RealEstateValuationsProviderInterfaceTest

  setup do
    @subject = Provider::Null.new
  end
end
