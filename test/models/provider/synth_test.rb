require "test_helper"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest

  setup do
    VCR.insert_cassette("synth_exchange_rate")
    @subject = Provider::Synth.new("FAKE_API_KEY")
  end

  teardown do
    VCR.eject_cassette
  end
end
