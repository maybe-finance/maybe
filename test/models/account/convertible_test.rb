require "test_helper"
require "ostruct"

class Account::ConvertibleTest < ActiveSupport::TestCase
  include EntriesTestHelper, ProviderTestHelper

  setup do
    @family = families(:empty)
    @family.update!(currency: "USD")

    # Foreign account (currency is not in the family's primary currency, so it will require exchange rates for net worth rollups)
    @account = @family.accounts.create!(name: "Test Account", currency: "EUR", balance: 10000, accountable: Depository.new)

    @provider = mock
    ExchangeRate.stubs(:provider).returns(@provider)
  end

  test "syncs required exchange rates for an account" do
    create_valuation(account: @account, date: 1.day.ago.to_date, amount: 9500, currency: "EUR")

    # Since we had a valuation 1 day ago, this account starts 2 days ago and needs daily exchange rates looking forward
    assert_equal 2.days.ago.to_date, @account.start_date

    ExchangeRate.delete_all

    provider_response = provider_success_response(
      [
        OpenStruct.new(from: "EUR", to: "USD", date: 2.days.ago.to_date, rate: 1.1),
        OpenStruct.new(from: "EUR", to: "USD", date: 1.day.ago.to_date, rate: 1.2),
        OpenStruct.new(from: "EUR", to: "USD", date: Date.current, rate: 1.3)
      ]
    )

    @provider.expects(:fetch_exchange_rates)
             .with(from: "EUR", to: "USD", start_date: 2.days.ago.to_date, end_date: Date.current)
             .returns(provider_response)

    assert_difference "ExchangeRate.count", 3 do
      @account.sync_required_exchange_rates
    end
  end

  test "does not sync rates for a domestic account" do
    @account.update!(currency: "USD")

    @provider.expects(:fetch_exchange_rates).never

    assert_no_difference "ExchangeRate.count" do
      @account.sync_required_exchange_rates
    end
  end
end
