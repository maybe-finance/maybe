require "test_helper"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest

  setup do
    @subject = Provider::Synth
  end
end
