require "test_helper"

module SecurityProviderInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "fetches security price" do
    aapl = securities(:aapl)

    VCR.use_cassette("#{vcr_key_prefix}/security_price") do
      response = @subject.fetch_security_price(aapl, date: Date.iso8601("2024-08-01"))
      assert response.success?
      assert response.data.price.present?
    end
  end

  test "fetches paginated securities prices" do
    aapl = securities(:aapl)

    VCR.use_cassette("#{vcr_key_prefix}/security_prices") do
      response = @subject.fetch_security_prices(
        aapl,
        start_date: Date.iso8601("2024-01-01"),
        end_date: Date.iso8601("2024-08-01")
      )

      assert response.success?
      assert 213, response.data.prices.count
    end
  end

  test "searches securities" do
    VCR.use_cassette("#{vcr_key_prefix}/security_search") do
      response = @subject.search_securities("AAPL", country_code: "US")
      securities = response.data.securities

      assert securities.any?
      security = securities.first
      assert_kind_of Security, security
      assert_equal "AAPL", security.ticker
    end
  end

  test "fetches security info" do
    aapl = securities(:aapl)

    VCR.use_cassette("#{vcr_key_prefix}/security_info") do
      response = @subject.fetch_security_info(aapl)
      info = response.data

      assert_equal "AAPL", info.ticker
      assert_equal "Apple Inc.", info.name
      assert info.logo_url.present?
      assert_equal "common stock", info.kind
      assert info.description.present?
    end
  end

  private
    def vcr_key_prefix
      @subject.class.name.demodulize.underscore
    end
end
