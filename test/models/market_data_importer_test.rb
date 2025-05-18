require "test_helper"
require "ostruct"

class MarketDataImporterTest < ActiveSupport::TestCase
  include ProviderTestHelper

  SNAPSHOT_START_DATE = MarketDataImporter::SNAPSHOT_DAYS.days.ago.to_date
  PROVIDER_BUFFER     = 5.days

  setup do
    Security::Price.delete_all
    ExchangeRate.delete_all
    Trade.delete_all
    Holding.delete_all
    Security.delete_all

    @provider = mock("provider")
    Provider::Registry.any_instance
                      .stubs(:get_provider)
                      .with(:synth)
                      .returns(@provider)
  end

  test "syncs required exchange rates" do
    family = Family.create!(name: "Smith", currency: "USD")
    family.accounts.create!(name: "Chequing",
                            currency: "CAD",
                            balance: 100,
                            accountable: Depository.new)

    # Seed stale rate so only the next missing day is fetched
    ExchangeRate.create!(from_currency: "CAD",
                         to_currency: "USD",
                         date: SNAPSHOT_START_DATE,
                         rate: 2.0)

    expected_start_date = (SNAPSHOT_START_DATE + 1.day) - PROVIDER_BUFFER
    end_date            = Date.current.in_time_zone("America/New_York").to_date

    @provider.expects(:fetch_exchange_rates)
             .with(from: "CAD",
                   to: "USD",
                   start_date: expected_start_date,
                   end_date: end_date)
             .returns(provider_success_response([
               OpenStruct.new(from: "CAD", to: "USD", date: SNAPSHOT_START_DATE, rate: 1.5)
             ]))

    before = ExchangeRate.count
    MarketDataImporter.new(mode: :snapshot).import_exchange_rates
    after  = ExchangeRate.count

    assert_operator after, :>, before, "Should insert at least one new exchange-rate row"
  end

  test "syncs security prices" do
    security = Security.create!(ticker: "AAPL", exchange_operating_mic: "XNAS")

    expected_start_date = SNAPSHOT_START_DATE - PROVIDER_BUFFER
    end_date            = Date.current.in_time_zone("America/New_York").to_date

    @provider.expects(:fetch_security_prices)
             .with(symbol: security.ticker,
                   exchange_operating_mic: security.exchange_operating_mic,
                   start_date: expected_start_date,
                   end_date: end_date)
             .returns(provider_success_response([
               OpenStruct.new(security: security,
                              date: SNAPSHOT_START_DATE,
                              price: 100,
                              currency: "USD")
             ]))

    @provider.stubs(:fetch_security_info)
             .with(symbol: "AAPL", exchange_operating_mic: "XNAS")
             .returns(provider_success_response(OpenStruct.new(name: "Apple", logo_url: "logo")))

    # Ignore exchange rate calls for this test
    @provider.stubs(:fetch_exchange_rates).returns(provider_success_response([]))

    MarketDataImporter.new(mode: :snapshot).import_security_prices

    assert_equal 1, Security::Price.where(security: security, date: SNAPSHOT_START_DATE).count
  end
end
