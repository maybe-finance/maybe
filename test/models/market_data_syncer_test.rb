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

    mock_provider.expects(:fetch_exchange_rates)
                 .with(from: "CAD", to: "USD", start_date: start_date, end_date: end_date)
                 .returns(provider_success_response([ OpenStruct.new(from: "CAD", to: "USD", date: start_date, rate: 1.0) ]))

    mock_provider.expects(:fetch_exchange_rates)
                 .with(from: "USD", to: "EUR", start_date: start_date, end_date: end_date)
                 .returns(provider_success_response([ OpenStruct.new(from: "USD", to: "EUR", date: start_date, rate: 1.0) ]))

    assert_difference "ExchangeRate.count", 1 do
      MarketDataSyncer.new.sync_exchange_rates
    end

    assert_equal 1.0, ExchangeRate.where(from_currency: "CAD", to_currency: "USD", date: start_date).first.rate
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

    mock_provider.expects(:fetch_security_prices)
                 .with("AAPL", start_date: start_date, end_date: end_date)
                 .returns(provider_success_response([ OpenStruct.new(security: aapl, date: start_date, price: 100, currency: "USD") ]))

    assert_difference "Security::Price.count", 1 do
      MarketDataSyncer.new.sync_prices
    end
  end

  private
    def empty_db
      Invitation.destroy_all
      Family.destroy_all
      Security.destroy_all
    end
end
