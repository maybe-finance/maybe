require "test_helper"

class ExchangeRateTest < ActiveSupport::TestCase
  test "get rate from db" do
    assert_equal exchange_rates(:day_30_ago_eur_to_usd),
      ExchangeRate.get_rate("EUR", "USD", 30.days.ago.to_date)
  end

  test "get rate from provider when it's not found in db" do
    Provided::ExchangeRate.any_instance
      .expects(:fetch_exchange_rate)
      .returns(ExchangeRate.new(base_currency: "USD", converted_currency: "MXN", rate: 1.0, date: Date.current))

    get_missing_exchange_rate
  end

  test "save provided rates to the db" do
    VCR.use_cassette("synth_exchange_rate") do
      assert_difference "ExchangeRate.count", 1 do
        get_missing_exchange_rate
      end
    end
  end

  private
    def get_missing_exchange_rate
      ExchangeRate.get_rate("USD", "MXN", Date.current)
    end
end
