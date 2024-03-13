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
