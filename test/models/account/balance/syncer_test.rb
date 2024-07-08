require "test_helper"
require "csv"

class Account::Balance::SyncerTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:savings)
    @syncer = Account::Balance::Syncer.new(@account)
  end

  test "syncs account with no entries" do
    assert_equal 0, @account.balances.count

    @syncer.run

    assert_equal 1, @account.balances.count
    assert_equal @account.balance, @account.balances.first
  end

  test "syncs acccount with valuations only" do
    flunk
  end

  test "syncs account with transactions only" do
    flunk
  end

  test "syncs account with valuations and transactions" do
    flunk
  end

  test "syncs account with transactions in multiple currencies" do
    flunk
  end

  test "converts foreign account balances family currency" do
    flunk
  end
end
