require "test_helper"

class Provider::NullTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest

  setup do
    @subject = Provider::Null.new
  end
end
