require "test_helper"

class Security::ResolverTest < ActiveSupport::TestCase
  setup do
    @provider = mock
    Security.stubs(:provider).returns(@provider)
  end

  test "resolves DB security" do
    # Given an existing security in the DB that exactly matches the lookup params
    db_security = Security.create!(ticker: "TSLA", exchange_operating_mic: "XNAS", country_code: "US")

    # The resolver should return the DB record and never hit the provider
    Security.expects(:search_provider).never

    resolved = Security::Resolver.new("TSLA", exchange_operating_mic: "XNAS", country_code: "US").resolve

    assert_equal db_security, resolved
  end

  test "resolves exact provider match" do
    # Provider returns multiple results, one of which exactly matches symbol + exchange (and country)
    exact_match = Security.new(ticker: "NVDA", exchange_operating_mic: "XNAS", country_code: "US")
    near_miss   = Security.new(ticker: "NVDA", exchange_operating_mic: "XNYS", country_code: "US")

    Security.expects(:search_provider)
            .with("NVDA", exchange_operating_mic: "XNAS", country_code: "US")
            .returns([ near_miss, exact_match ])

    assert_difference "Security.count", 1 do
      resolved = Security::Resolver.new("NVDA", exchange_operating_mic: "XNAS", country_code: "US").resolve

      assert resolved.persisted?
      assert_equal "NVDA", resolved.ticker
      assert_equal "XNAS", resolved.exchange_operating_mic
      assert_equal "US",   resolved.country_code
      refute resolved.offline, "Exact provider matches should not be marked offline"
    end
  end

  test "resolves close provider match" do
    # No exact match – resolver should choose the most relevant close match based on exchange + country ranking
    preferred = Security.new(ticker: "TEST1", exchange_operating_mic: "XNAS", country_code: "US")
    other     = Security.new(ticker: "TEST2", exchange_operating_mic: "XNYS", country_code: "GB")

    # Return in reverse-priority order to prove the sorter works
    Security.expects(:search_provider)
            .with("TEST", exchange_operating_mic: "XNAS")
            .returns([ other, preferred ])

    assert_difference "Security.count", 1 do
      resolved = Security::Resolver.new("TEST", exchange_operating_mic: "XNAS").resolve

      assert resolved.persisted?
      assert_equal "TEST1", resolved.ticker
      assert_equal "XNAS",  resolved.exchange_operating_mic
      assert_equal "US",    resolved.country_code
      refute resolved.offline, "Provider matches should not be marked offline"
    end
  end

  test "resolves offline security" do
    Security.expects(:search_provider).returns([])

    assert_difference "Security.count", 1 do
      resolved = Security::Resolver.new("FOO").resolve

      assert resolved.persisted?, "Offline security should be saved"
      assert_equal "FOO", resolved.ticker
      assert resolved.offline, "Offline securities should be flagged offline"
    end
  end

  test "returns nil when symbol blank" do
    assert_raises(ArgumentError) { Security::Resolver.new(nil).resolve }
    assert_raises(ArgumentError) { Security::Resolver.new("").resolve }
  end
end
