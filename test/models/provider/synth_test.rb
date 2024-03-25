require "test_helper"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest
  include MerchantDataProviderInterfaceTest

  setup do
    @subject = Provider::Synth.new(ENV["SYNTH_API_KEY"])
  end
end
