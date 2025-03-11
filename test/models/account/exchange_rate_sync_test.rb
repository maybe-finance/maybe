require "test_helper"
require "ostruct"

class Account::ExchangeRateSyncTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @family = families(:empty)
    @family.update!(currency: "USD")

    # Foreign account (currency is not in the family's primary currency, so it will require exchange rates for net worth rollups)
    @account = @family.accounts.create!(name: "Test Account", currency: "EUR", balance: 10000, accountable: Depository.new)

    @provider = mock
    ExchangeRate.stubs(:provider).returns(@provider)
  end

  test "syncs required exchange rates for an account" do
    create_valuation(account: @account, date: 5.days.ago.to_date, amount: 9500, currency: "EUR")

    # Since we had a valuation 5 days ago, this account starts 6 days ago and needs daily exchange rates looking forward
    assert_equal 6.days.ago.to_date, @account.start_date

    @provider.expects(:fetch_exchange_rates)
             .with(
                from: "EUR",
                to: "USD",
                start_date: 6.days.ago.to_date,
                end_date: Date.current
              ).returns(
                OpenStruct.new(
                  success?: true,
                  rates: [
                    OpenStruct.new(date: 6.days.ago.to_date, rate: 1.1),
                    OpenStruct.new(date: 5.days.ago.to_date, rate: 1.2),
                    OpenStruct.new(date: 4.days.ago.to_date, rate: 1.3),
                    OpenStruct.new(date: 3.days.ago.to_date, rate: 1.4),
                    OpenStruct.new(date: 2.days.ago.to_date, rate: 1.5),
                    OpenStruct.new(date: 1.day.ago.to_date, rate: 1.6),
                    OpenStruct.new(date: Date.current, rate: 1.7)
                  ]
                )
              )

    assert_difference "ExchangeRate.count", 7 do
      Account::ExchangeRateSync.new(@account).sync_rates
    end
  end

  test "does not sync rates for a domestic account" do
    @account.update!(currency: "USD")

    @provider.expects(:fetch_exchange_rates).never

    assert_no_difference "ExchangeRate.count" do
      Account::ExchangeRateSync.new(@account).sync_rates
    end
  end
end
