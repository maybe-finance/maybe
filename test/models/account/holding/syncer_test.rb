require "test_helper"

class Account::Holding::SyncerTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @family = families(:empty)
    @account = @family.accounts.create!(name: "Test", balance: 20000, cash_balance: 20000, currency: "USD", accountable: Investment.new)
    @aapl = securities(:aapl)
  end

  test "syncs holdings" do
    create_trade(@aapl, account: @account, qty: 1, price: 200, date: Date.current)

    # Should have yesterday's and today's holdings
    assert_difference "@account.holdings.count", 2 do
      Account::Holding::Syncer.new(@account, strategy: :forward).sync_holdings
    end
  end

  test "purges stale holdings for unlinked accounts" do
    # Since the account has no entries, there should be no holdings
    Account::Holding.create!(account: @account, security: @aapl, qty: 1, price: 100, amount: 100, currency: "USD", date: Date.current)

    assert_difference "Account::Holding.count", -1 do
      Account::Holding::Syncer.new(@account, strategy: :forward).sync_holdings
    end
  end
end
