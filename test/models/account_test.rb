require "test_helper"

class AccountTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @account = accounts(:checking)
    @family = families(:dylan_family)
  end

  test "can sync later" do
    assert_enqueued_with(job: AccountSyncJob, args: [ @account, start_date: Date.current ]) do
      @account.sync_later start_date: Date.current
    end
  end

  test "can sync" do
    start_date = 10.days.ago.to_date

    mock_sync = mock("Account::Sync")
    mock_sync.expects(:run).once

    Account::Sync.expects(:for).with(@account, start_date: start_date).returns(mock_sync).once

    @account.sync start_date: start_date
  end

  test "recognizes foreign currency account" do
    regular_account = accounts(:checking)
    foreign_account = accounts(:eur_checking)
    assert_not regular_account.foreign_currency?
    assert foreign_account.foreign_currency?
  end

  test "recognizes multi currency account" do
    regular_account = accounts(:checking)
    multi_currency_account = accounts(:multi_currency)
    assert_not regular_account.multi_currency?
    assert multi_currency_account.multi_currency?
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

    assert_equal 4, depositories.children.count
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
    assert_equal 1, accounts(:savings).series.values.count
  end

  test "generates balance series in period" do
    assert_equal 2, @account.series(period: Period.last_30_days).values.count

    @account.balances.create! date: 31.days.ago.to_date, balance: 5000, currency: "USD" # out of period range
    @account.balances.create! date: 30.days.ago.to_date, balance: 5000, currency: "USD" # in range

    assert_equal 3, @account.series(period: Period.last_30_days).values.count
  end

  test "generates empty series if no balances and no exchange rate" do
    account = accounts(:eur_checking)

    assert_equal 0, account.series(currency: "NZD").values.count
  end
end
