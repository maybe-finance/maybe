require "test_helper"

class Account::SyncableTest < ActiveSupport::TestCase
  test "account has no balances until synced" do
    account = accounts(:savings_with_valuation_overrides)

    assert_equal 0, account.balances.count
  end

  test "account has balances after syncing" do
    account = accounts(:savings_with_valuation_overrides)
    account.sync

    assert_equal 31, account.balances.count
  end

  test "partial sync with missing historical balances performs a full sync" do
    account = accounts(:savings_with_valuation_overrides)
    account.sync 10.days.ago.to_date

    assert_equal 31, account.balances.count
  end

  test "balances are updated after syncing" do
    account = accounts(:savings_with_valuation_overrides)
    balance_date = 10.days.ago
    account.balances.create!(date: balance_date, balance: 1000)
    account.sync

    assert_equal 19500, account.balances.find_by(date: balance_date)[:balance]
  end

  test "balances before sync start date are not updated after syncing" do
    account = accounts(:savings_with_valuation_overrides)
    balance_date = 10.days.ago
    account.balances.create!(date: balance_date, balance: 1000)
    account.sync 5.days.ago.to_date

    assert_equal 1000, account.balances.find_by(date: balance_date)[:balance]
  end

  test "balances after sync start date are updated after syncing" do
    account = accounts(:savings_with_valuation_overrides)
    balance_date = 10.days.ago
    account.balances.create!(date: balance_date, balance: 1000)
    account.sync 20.days.ago.to_date

    assert_equal 19500, account.balances.find_by(date: balance_date)[:balance]
  end

  test "balance on the sync date is updated after syncing" do
    account = accounts(:savings_with_valuation_overrides)
    balance_date = 5.days.ago
    account.balances.create!(date: balance_date, balance: 1000)
    account.sync balance_date.to_date

    assert_equal 19700, account.balances.find_by(date: balance_date)[:balance]
  end

  test "foreign currency account has balances in each currency after syncing" do
    account = accounts(:eur_checking)
    account.sync

    assert_equal 62, account.balances.count
    assert_equal 31, account.balances.where(currency: "EUR").count
    assert_equal 31, account.balances.where(currency: "USD").count
  end

  test "stale balances are purged after syncing" do
    account = accounts(:savings_with_valuation_overrides)

    # Create old, stale balances that should be purged (since they are before account start date)
    account.balances.create!(date: 1.year.ago, balance: 1000)
    account.balances.create!(date: 2.years.ago, balance: 2000)
    account.balances.create!(date: 3.years.ago, balance: 3000)

    account.sync

    assert_equal 31, account.balances.count
  end
end
