require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include SyncableInterfaceTest, Account::EntriesTestHelper

  setup do
    @account = @syncable = accounts(:depository)
    @family = families(:dylan_family)
  end

  test "can destroy" do
    assert_difference "Account.count", -1 do
      @account.destroy
    end
  end

  test "generates balance series" do
    assert_equal 2, @account.balance_series.values.count
  end

  test "generates balance series with single value if no balances" do
    @account.balances.delete_all
    assert_equal 1, @account.balance_series.values.count
  end

  test "generates balance series in period" do
    @account.balances.delete_all
    @account.balances.create! date: 31.days.ago.to_date, balance: 5000, currency: "USD" # out of period range
    @account.balances.create! date: 30.days.ago.to_date, balance: 5000, currency: "USD" # in range

    assert_equal 1, @account.balance_series(period: Period.last_30_days).values.count
  end

  test "generates empty series if no balances and no exchange rate" do
    with_env_overrides SYNTH_API_KEY: nil do
      assert_equal 0, @account.balance_series(currency: "NZD").values.count
    end
  end
end
