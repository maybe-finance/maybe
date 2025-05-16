require "test_helper"
require "ostruct"

class MarketDataSyncerTest < ActiveSupport::TestCase
  include EntriesTestHelper, ProviderTestHelper

  test "syncs exchange rates with upsert" do
    empty_db

    family1 = Family.create!(name: "Family 1", currency: "USD")
    account1 = family1.accounts.create!(name: "Account 1", currency: "USD", balance: 100, accountable: Depository.new)
    account2 = family1.accounts.create!(name: "Account 2", currency: "CAD", balance: 100, accountable: Depository.new)

    family2 = Family.create!(name: "Family 2", currency: "EUR")
    account3 = family2.accounts.create!(name: "Account 3", currency: "EUR", balance: 100, accountable: Depository.new)
    account4 = family2.accounts.create!(name: "Account 4", currency: "USD", balance: 100, accountable: Depository.new)

    mock_provider = mock
    Provider::Registry.any_instance.expects(:get_provider).with(:synth).returns(mock_provider).at_least_once

    start_date = 1.month.ago.to_date
    end_date = Date.current.in_time_zone("America/New_York").to_date

    # Put an existing rate in DB to test upsert
    ExchangeRate.create!(from_currency: "CAD", to_currency: "USD", date: start_date, rate: 2.0)

    # The individual syncers fetch with a 5-day buffer to ensure we have a «starting» price/rate
    provider_start_date = get_provider_fetch_start_date(start_date)
    provider_start_date_for_cad_usd = get_provider_fetch_start_date(start_date + 1.day) # first missing date is +1 day

    mock_provider.expects(:fetch_exchange_rates)
                 .with(from: "CAD", to: "USD", start_date: provider_start_date_for_cad_usd, end_date: end_date)
                 .returns(provider_success_response([ OpenStruct.new(from: "CAD", to: "USD", date: start_date, rate: 1.0) ]))

    mock_provider.expects(:fetch_exchange_rates)
                 .with(from: "USD", to: "EUR", start_date: provider_start_date, end_date: end_date)
                 .returns(provider_success_response([ OpenStruct.new(from: "USD", to: "EUR", date: start_date, rate: 1.0) ]))

    before_count = ExchangeRate.count
    MarketDataSyncer.new.sync_exchange_rates
    after_count = ExchangeRate.count

    assert_operator after_count, :>, before_count, "Expected at least one new exchange-rate row to be inserted"

    # The original CAD→USD rate on start_date should remain (no clear_cache), so value stays 2.0
    assert_equal 2.0, ExchangeRate.where(from_currency: "CAD", to_currency: "USD", date: start_date).first.rate
  end

  test "syncs security prices with upsert" do
    empty_db

    aapl = Security.create!(ticker: "AAPL", exchange_operating_mic: "XNAS")

    family = Family.create!(name: "Family 1", currency: "USD")
    account = family.accounts.create!(name: "Account 1", currency: "USD", balance: 100, accountable: Investment.new)

    mock_provider = mock
    Provider::Registry.any_instance.expects(:get_provider).with(:synth).returns(mock_provider).at_least_once

    start_date = 1.month.ago.to_date
    end_date = Date.current.in_time_zone("America/New_York").to_date

    # The individual syncers fetch with a 5-day buffer to ensure we have a «starting» price/rate
    provider_start_date = get_provider_fetch_start_date(start_date)

    mock_provider.expects(:fetch_security_prices)
                 .with(aapl, start_date: provider_start_date, end_date: end_date)
                 .returns(provider_success_response([ OpenStruct.new(security: aapl, date: start_date, price: 100, currency: "USD") ]))

    # The syncer also enriches security details, so stub that out as well
    mock_provider.stubs(:fetch_security_info)
                 .with(symbol: "AAPL", exchange_operating_mic: "XNAS")
                 .returns(OpenStruct.new(name: "Apple", logo_url: "logo"))

    MarketDataSyncer.new.sync_prices

    assert_equal 1, Security::Price.where(security: aapl, date: start_date).count
  end

  private
    def empty_db
      Invitation.destroy_all
      Family.destroy_all
      Security.destroy_all
    end

    # Match the internal syncer logic of adding a 5-day buffer before provider calls
    def get_provider_fetch_start_date(start_date)
      start_date - 5.days
    end
end
