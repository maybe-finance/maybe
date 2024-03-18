require "test_helper"
require "csv"

class FamilyTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)

    @family.accounts.each do |account|
      account.sync
    end
  end

  test "should have many users" do
    assert @family.users.size > 0
    assert @family.users.include?(users(:family_admin))
  end

  test "should have many accounts" do
    assert @family.accounts.size > 0
  end

  test "should destroy dependent users" do
    assert_difference("User.count", -@family.users.count) do
      @family.destroy
    end
  end

  test "should destroy dependent accounts" do
    assert_difference("Account.count", -@family.accounts.count) do
      @family.destroy
    end
  end

  test "should destroy dependent transaction categories" do
    assert_difference("Transaction::Category.count", -@family.transaction_categories.count) do
      @family.destroy
    end
  end

  test "should calculate total assets" do
    assert_equal Money.new(25550), @family.assets
  end

  test "should calculate total liabilities" do
    assert_equal Money.new(1000), @family.liabilities
  end

  test "should calculate net worth" do
    assert_equal Money.new(24550), @family.net_worth
  end

  test "should calculate snapshot correctly" do
    # See this Google Sheet for calculations and expected results for dylan_family:
    # https://docs.google.com/spreadsheets/d/18LN5N-VLq4b49Mq1fNwF7_eBiHSQB46qQduRtdAEN98/edit?usp=sharing
    expected_snapshots = CSV.read("test/fixtures/family/expected_snapshots.csv", headers: true).map do |row|
      {
        "date" => (Date.current + row["date_offset"].to_i.days).to_date,
        "net_worth" => row["net_worth"],
        "assets" => row["assets"],
        "liabilities" => row["liabilities"]
      }
    end

    asset_series = @family.snapshot[:asset_series]
    liability_series = @family.snapshot[:liability_series]
    net_worth_series = @family.snapshot[:net_worth_series]

    assert_equal expected_snapshots.count, asset_series.data.count
    assert_equal expected_snapshots.count, liability_series.data.count
    assert_equal expected_snapshots.count, net_worth_series.data.count

    expected_snapshots.each_with_index do |row, index|
      expected = {
        date: row["date"],
        assets: row["assets"].to_d,
        liabilities: row["liabilities"].to_d,
        net_worth: row["net_worth"].to_d
      }

      actual = {
        date: asset_series.data[index][:date],
        assets: asset_series.data[index][:value].amount,
        liabilities: liability_series.data[index][:value].amount,
        net_worth: net_worth_series.data[index][:value].amount
      }

      assert_equal expected, actual
    end
  end

  test "should exclude disabled accounts from calculations" do
    assets_before = @family.assets
    liabilities_before = @family.liabilities
    net_worth_before = @family.net_worth

    disabled_checking = accounts(:checking)
    disabled_cc = accounts(:credit_card)

    disabled_checking.update!(is_active: false)
    disabled_cc.update!(is_active: false)

    assert_equal assets_before - disabled_checking.balance, @family.assets
    assert_equal liabilities_before - disabled_cc.balance, @family.liabilities
    assert_equal net_worth_before - disabled_checking.balance + disabled_cc.balance, @family.net_worth
  end

  test "calculates balances by type" do
    verify_balances_by_type(
      period: Period.all,
      expected_asset_total: BigDecimal("25550"),
      expected_liability_total: BigDecimal("1000"),
      expected_asset_groups: {
        "Account::OtherAsset" => { end_balance: BigDecimal("550"), start_balance: BigDecimal("400"), allocation: 2.15 },
        "Account::Depository" => { end_balance: BigDecimal("25000"), start_balance: BigDecimal("25250"), allocation: 97.85 }
      },
      expected_liability_groups: {
        "Account::Credit" => { end_balance: BigDecimal("1000"), start_balance: BigDecimal("1040"), allocation: 100 }
      }
    )
  end

  test "calculates balances by type with a date range filter" do
    verify_balances_by_type(
      period: Period.new(name: "custom", date_range: 7.days.ago.to_date..2.days.ago.to_date),
      expected_asset_total: BigDecimal("26050"),
      expected_liability_total: BigDecimal("1000"),
      expected_asset_groups: {
        "Account::OtherAsset" => { end_balance: BigDecimal("550"), start_balance: BigDecimal("700"), allocation: 2.11 },
        "Account::Depository" => { end_balance: BigDecimal("25500"), start_balance: BigDecimal("24510"), allocation: 97.89 }
      },
      expected_liability_groups: {
        "Account::Credit" => { end_balance: BigDecimal("1000"), start_balance: BigDecimal("990"), allocation: 100 }
      }
    )
  end

  test "calculates balances by type with disabled account" do
    disabled_checking = accounts(:checking).update!(is_active: false)

    verify_balances_by_type(
      period: Period.all,
      expected_asset_total: BigDecimal("20550"),
      expected_liability_total: BigDecimal("1000"),
      expected_asset_groups: {
        "Account::OtherAsset" => { end_balance: BigDecimal("550"), start_balance: BigDecimal("400"), allocation: 2.68 },
        "Account::Depository" => { end_balance: BigDecimal("20000"), start_balance: BigDecimal("21250"), allocation: 97.32 }
      },
      expected_liability_groups: {
        "Account::Credit" => { end_balance: BigDecimal("1000"), start_balance: BigDecimal("1040"), allocation: 100 }
      }
    )
  end

  private

  def verify_balances_by_type(period:, expected_asset_total:, expected_liability_total:, expected_asset_groups:, expected_liability_groups:)
    result = @family.accounts.by_group(period)

    asset_total = result[:asset][:total]
    liability_total = result[:liability][:total]

    assert_equal expected_asset_total, asset_total
    assert_equal expected_liability_total, liability_total

    asset_groups = result[:asset][:groups]
    liability_groups = result[:liability][:groups]

    assert_equal expected_asset_groups.keys, asset_groups.keys
    expected_asset_groups.each do |type, expected_values|
      assert_equal expected_values[:end_balance], asset_groups[type][:end_balance]
      assert_equal expected_values[:start_balance], asset_groups[type][:start_balance]
      assert_equal expected_values[:allocation], asset_groups[type][:allocation]
    end

    assert_equal expected_liability_groups.keys, liability_groups.keys
    expected_liability_groups.each do |type, expected_values|
      assert_equal expected_values[:end_balance], liability_groups[type][:end_balance]
      assert_equal expected_values[:start_balance], liability_groups[type][:start_balance]
      assert_equal expected_values[:allocation], liability_groups[type][:allocation]
    end
  end
end
