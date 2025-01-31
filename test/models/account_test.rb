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

  test "groups accounts by type" do
    result = @family.accounts.by_group(period: Period.all)
    assets = result[:assets]
    liabilities = result[:liabilities]

    assert_equal @family.assets, assets.sum
    assert_equal @family.liabilities, liabilities.sum

    depositories = assets.children.find { |group| group.name == "Depository" }
    properties = assets.children.find { |group| group.name == "Property" }
    vehicles = assets.children.find { |group| group.name == "Vehicle" }
    investments = assets.children.find { |group| group.name == "Investment" }
    other_assets = assets.children.find { |group| group.name == "OtherAsset" }

    credits = liabilities.children.find { |group| group.name == "CreditCard" }
    loans = liabilities.children.find { |group| group.name == "Loan" }
    other_liabilities = liabilities.children.find { |group| group.name == "OtherLiability" }

    assert_equal 2, depositories.children.count
    assert_equal 1, properties.children.count
    assert_equal 1, vehicles.children.count
    assert_equal 1, investments.children.count
    assert_equal 1, other_assets.children.count

    assert_equal 1, credits.children.count
    assert_equal 1, loans.children.count
    assert_equal 1, other_liabilities.children.count
  end

  test "generates balance series" do
    assert_equal 2, @account.series.values.count
  end

  test "generates balance series with single value if no balances" do
    @account.balances.delete_all
    assert_equal 1, @account.series.values.count
  end

  test "generates balance series in period" do
    @account.balances.delete_all
    @account.balances.create! date: 31.days.ago.to_date, balance: 5000, currency: "USD" # out of period range
    @account.balances.create! date: 30.days.ago.to_date, balance: 5000, currency: "USD" # in range

    assert_equal 1, @account.series(period: Period.last_30_days).values.count
  end

  test "generates empty series if no balances and no exchange rate" do
    with_env_overrides SYNTH_API_KEY: nil do
      assert_equal 0, @account.series(currency: "NZD").values.count
    end
  end

  test "auto-matches transfers" do
    outflow_entry = create_transaction(date: 1.day.ago.to_date, account: @account, amount: 500)
    inflow_entry = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)

    assert_difference -> { Transfer.count } => 1 do
      @account.auto_match_transfers!
    end
  end

  # In this scenario, our matching logic should find 4 potential matches.  These matches should be ranked based on
  # days apart, then de-duplicated so that we aren't auto-matching the same transaction across multiple transfers.
  test "when 2 options exist, only auto-match one at a time, ranked by days apart" do
    yesterday_outflow = create_transaction(date: 1.day.ago.to_date, account: @account, amount: 500)
    yesterday_inflow = create_transaction(date: 1.day.ago.to_date, account: accounts(:credit_card), amount: -500)

    today_outflow = create_transaction(date: Date.current, account: @account, amount: 500)
    today_inflow = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)

    assert_difference -> { Transfer.count } => 2 do
      @account.auto_match_transfers!
    end
  end

  test "does not auto-match any transfers that have been rejected by user already" do
    outflow = create_transaction(date: Date.current, account: @account, amount: 500)
    inflow = create_transaction(date: Date.current, account: accounts(:credit_card), amount: -500)

    RejectedTransfer.create!(inflow_transaction_id: inflow.entryable_id, outflow_transaction_id: outflow.entryable_id)

    assert_no_difference -> { Transfer.count } do
      @account.auto_match_transfers!
    end
  end
end
