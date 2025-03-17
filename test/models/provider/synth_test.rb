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

  test "enriches transaction" do
    VCR.use_cassette("synth/transaction_enrich") do
      response = @synth.enrich_transaction(
        "UBER EATS",
        amount: 25.50,
        date: Date.iso8601("2025-03-16"),
        city: "San Francisco",
        state: "CA",
        country: "US"
      )

      data = response.data
      assert data.name.present?
      assert data.category.present?
    end
  end
end
