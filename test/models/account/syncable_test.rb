require "test_helper"

class Account::SyncableTest < ActiveSupport::TestCase
    test "account has no balances until synced" do
        account = accounts(:savings_with_valuation_overrides)
        account.accountable = account_depositories(:savings)

        assert_equal 0, account.balances.count
    end

    test "account has balances after syncing" do
        account = accounts(:savings_with_valuation_overrides)
        account.accountable = account_depositories(:savings)
        account.sync

        assert_equal 31, account.balances.count
    end

    test "stale balances are purged after syncing" do
        account = accounts(:savings_with_valuation_overrides)
        account.accountable = account_depositories(:savings)

        # Create old, stale balances that should be purged (since they are before account start date)
        account.balances.create!(date: 1.year.ago, balance: 1000)
        account.balances.create!(date: 2.years.ago, balance: 2000)
        account.balances.create!(date: 3.years.ago, balance: 3000)

        account.sync

        assert_equal 31, account.balances.count
    end
end
