require "test_helper"

class ExchangeRateTest < ActiveSupport::TestCase
  test "find rate in db" do
    assert_equal exchange_rates(:day_30_ago_eur_to_usd),
      ExchangeRate.find_rate_or_fetch(from: "EUR", to: "USD", date: 30.days.ago.to_date)
  end

  test "fetch rate from provider when it's not found in db" do
    Provided::ExchangeRate.any_instance
      .expects(:fetch)
      .returns(ExchangeRate.new(base_currency: "USD", converted_currency: "MXN", rate: 1.0, date: Date.parse("2024-03-24")))

    ExchangeRate.find_rate_or_fetch from: "USD", to: "MXN", date: Date.parse("2024-03-24")
  end

  test "provided rates are saved to the db" do
    VCR.use_cassette("synth_exchange_rate") do
      assert_difference "ExchangeRate.count", 1 do
        ExchangeRate.find_rate_or_fetch from: "USD", to: "MXN", date: Date.parse("2024-03-24")
      end
    end
  end
end
