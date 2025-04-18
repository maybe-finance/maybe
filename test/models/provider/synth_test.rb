require "test_helper"
require "ostruct"

class Provider::SynthTest < ActiveSupport::TestCase
  include ExchangeRateProviderInterfaceTest, SecurityProviderInterfaceTest

  setup do
    @subject = @synth = Provider::Synth.new(ENV["SYNTH_API_KEY"])
  end

  test "health check" do
    VCR.use_cassette("synth/health") do
      assert @synth.healthy?
    end
  end

  test "usage info" do
    VCR.use_cassette("synth/usage") do
      usage = @synth.usage.data
      assert usage.used.present?
      assert usage.limit.present?
      assert usage.utilization.present?
      assert usage.plan.present?
    end
  end
end
