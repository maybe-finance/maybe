require "test_helper"

module SecurityProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "fetches security price" do
    aapl = securities(:aapl)

    VCR.use_cassette("#{vcr_key_prefix}/security_price") do
      response = @subject.fetch_security_price(symbol: aapl.ticker, exchange_operating_mic: aapl.exchange_operating_mic, date: Date.iso8601("2024-08-01"))

      assert response.success?
      assert response.data.present?
    end
  end

  test "fetches paginated securities prices" do
    aapl = securities(:aapl)

    VCR.use_cassette("#{vcr_key_prefix}/security_prices") do
      response = @subject.fetch_security_prices(
        symbol: aapl.ticker,
        exchange_operating_mic: aapl.exchange_operating_mic,
        start_date: Date.iso8601("2024-01-01"),
        end_date: Date.iso8601("2024-08-01")
      )

      assert response.success?
      assert response.data.first.date.is_a?(Date)
      assert_equal 147, response.data.count # Synth won't return prices on weekends / holidays, so less than total day count of 213
    end
  end

  test "searches securities" do
    VCR.use_cassette("#{vcr_key_prefix}/security_search") do
      response = @subject.search_securities("AAPL", country_code: "US")
      securities = response.data

      assert securities.any?
      security = securities.first
      assert_equal "AAPL", security.symbol
    end
  end

  test "fetches security info" do
    aapl = securities(:aapl)

    VCR.use_cassette("#{vcr_key_prefix}/security_info") do
      response = @subject.fetch_security_info(
        symbol: aapl.ticker,
        exchange_operating_mic: aapl.exchange_operating_mic
      )

      info = response.data

      assert_equal "AAPL", info.symbol
      assert_equal "Apple Inc.", info.name
      assert_equal "common stock", info.kind
      assert info.logo_url.present?
      assert info.description.present?
    end
  end

  private
    def vcr_key_prefix
      @subject.class.name.demodulize.underscore
    end
end
