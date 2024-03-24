require "test_helper"

class Provider::LocalTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest

  setup do
    @subject = Provider::Local.new
  end
end
