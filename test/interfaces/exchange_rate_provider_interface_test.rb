require "test_helper"

module ExchangeRateProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "fetches single exchange rate" do
    VCR.use_cassette("#{vcr_key_prefix}/exchange_rate") do
      response = @subject.fetch_exchange_rate(
        from: "USD",
        to: "GBP",
        date: Date.parse("01.01.2024")
      )

      rate = response.data

      assert_equal "USD", rate.from
      assert_equal "GBP", rate.to
      assert rate.date.is_a?(Date)
      assert_in_delta 0.78, rate.rate, 0.01
    end
  end

  test "fetches paginated exchange_rate historical data" do
    VCR.use_cassette("#{vcr_key_prefix}/exchange_rates") do
      response = @subject.fetch_exchange_rates(
        from: "USD", to: "GBP", start_date: Date.parse("01.01.2024"), end_date: Date.parse("31.07.2024")
      )

      assert_equal 213, response.data.count # 213 days between 01.01.2024 and 31.07.2024
      assert response.data.first.date.is_a?(Date)
    end
  end

  private
    def vcr_key_prefix
      @subject.class.name.demodulize.underscore
    end
end
