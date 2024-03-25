require "test_helper"

class Provider::ZillowTest < ActiveSupport::TestCase
  include RealEstateValuationsProviderInterfaceTest

  setup do
    @subject = Provider::Zillow.new("FAKE_API_KEY")
  end
end
