require "test_helper"

class Account::Balance::SyncerTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(
      name: "Test",
      balance: 20000,
      cash_balance: 20000,
      currency: "USD",
      accountable: Investment.new
    )
  end

  test "syncs balances" do
    Holding::Syncer.any_instance.expects(:sync_holdings).returns([]).once

    @account.expects(:start_date).returns(2.days.ago.to_date)

    Account::Balance::ForwardCalculator.any_instance.expects(:calculate).returns(
      [
        Account::Balance.new(date: 1.day.ago.to_date, balance: 1000, cash_balance: 1000, currency: "USD"),
        Account::Balance.new(date: Date.current, balance: 1000, cash_balance: 1000, currency: "USD")
      ]
    )

    assert_difference "@account.balances.count", 2 do
      Account::Balance::Syncer.new(@account, strategy: :forward).sync_balances
    end
  end

  test "purges stale balances and holdings" do
    # Balance before start date is stale
    @account.expects(:start_date).returns(2.days.ago.to_date).twice
    stale_balance = Account::Balance.new(date: 3.days.ago.to_date, balance: 10000, cash_balance: 10000, currency: "USD")

    Account::Balance::ForwardCalculator.any_instance.expects(:calculate).returns(
      [
        stale_balance,
        Account::Balance.new(date: 2.days.ago.to_date, balance: 10000, cash_balance: 10000, currency: "USD"),
        Account::Balance.new(date: 1.day.ago.to_date, balance: 1000, cash_balance: 1000, currency: "USD"),
        Account::Balance.new(date: Date.current, balance: 1000, cash_balance: 1000, currency: "USD")
      ]
    )

    assert_difference "@account.balances.count", 3 do
      Account::Balance::Syncer.new(@account, strategy: :forward).sync_balances
    end
  end
end
