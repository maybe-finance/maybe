require "test_helper"

class AccountSyncerTest < ActiveSupport::TestCase
    test "account has no balances until synced" do
        account = accounts(:savings_with_valuation_overrides)
        account.accountable = account_depositories(:savings)

        assert_equal 0, account.balances.count

        AccountSyncer.new(account).sync

        assert_equal 31, account.balances.count

        # Create old, stale balance and re-sync.  Should be purged.
        account.balances.create!(date: 1.year.ago, balance: 1000)
        AccountSyncer.new(account).sync

        assert_equal 31, account.balances.count
    end

    test "syncs account with only valuations" do
        account = accounts(:collectable)
        account.accountable = account_other_assets(:one)

        AccountSyncer.new(account).sync

        expected_balances = [
            400, 400, 400, 400, 400, 400, 400, 400, 400, 400,
            400, 400, 400, 400, 400, 400, 400, 400, 700, 700,
            700, 700, 700, 700, 700, 700, 550, 550, 550, 550,
            550
        ].map(&:to_d)

        assert_equal expected_balances, account.balances.order(:date).map(&:balance)
    end

    test "syncs account with only transactions" do
        account = accounts(:checking)
        account.accountable = account_depositories(:checking)

        AccountSyncer.new(account).sync

        expected_balances = [
            4000, 3985, 3985, 3985, 3985, 3985, 3985, 3985, 5060, 5060,
            5060, 5060, 5060, 5060, 5060, 5040, 5040, 5040, 5010, 5010,
            5010, 5010, 5010, 5010, 5010, 5000, 5000, 5000, 5000, 5000,
            5000
        ].map(&:to_d)

        assert_equal expected_balances, account.balances.order(:date).map(&:balance)
    end

    test "syncs account with both valuations and transactions" do
        account = accounts(:savings_with_valuation_overrides)
        account.accountable = account_depositories(:savings)
        AccountSyncer.new(account).sync

        expected_balances = [
            21250, 21750, 21750, 21750, 21750, 21000, 21000, 21000, 21000, 21000,
            21000, 21000, 19000, 19000, 19000, 19000, 19000, 19000, 19500, 19500,
            19500, 19500, 19500, 19500, 19500, 19700, 19700, 20500, 20500, 20500,
            20500
        ].map(&:to_d)

        assert_equal expected_balances, account.balances.order(:date).map(&:balance)
    end

    test "stale account balances are purged" do
        account = accounts(:savings_with_valuation_overrides)
        account.accountable = account_depositories(:savings)

        # Create old, stale balances that should be purged (since they are before account start date)
        account.balances.create!(date: 1.year.ago, balance: 1000)
        account.balances.create!(date: 2.years.ago, balance: 2000)
        account.balances.create!(date: 3.years.ago, balance: 3000)

        AccountSyncer.new(account).sync

        assert_equal 31, account.balances.count
    end
end
