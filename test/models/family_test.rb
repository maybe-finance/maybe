require "test_helper"

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

  test "should calculate total assets" do
    assert_equal BigDecimal("25550"), @family.assets
  end

  test "should calculate total liabilities" do
    assert_equal BigDecimal("1000"), @family.liabilities
  end

  test "should calculate net worth" do
    assert_equal BigDecimal("24550"), @family.net_worth
  end

  test "calculates asset series" do
    # Sum of expected balances for all asset accounts in balance_calculator_test.rb
    expected_balances = [
      25650, 26135, 26135, 26135, 26135, 25385, 25385, 25385, 26460, 26460,
      26460, 26460, 24460, 24460, 24460, 24440, 24440, 24440, 25210, 25210,
      25210, 25210, 25210, 25210, 25210, 25400, 25250, 26050, 26050, 26050,
      25550
    ].map(&:to_d)

    assert_equal expected_balances, @family.asset_series.data.map { |b| b[:value].amount }
  end

  test "calculates liability series" do
    # Sum of expected balances for all liability accounts in balance_calculator_test.rb
    expected_balances = [
      1040, 940, 940, 940, 940, 940, 940, 940, 940, 940,
      940, 940, 940, 940, 940, 960, 960, 960, 990, 990,
      990, 990, 990, 990, 990, 1000, 1000, 1000, 1000, 1000,
      1000
    ].map(&:to_d)

    assert_equal expected_balances, @family.liability_series.data.map { |b| b[:value].amount }
  end

  test "calculates net worth" do
    # Net difference between asset and liability series above
    expected_balances = [
      24610, 25195, 25195, 25195, 25195, 24445, 24445, 24445, 25520, 25520,
      25520, 25520, 23520, 23520, 23520, 23480, 23480, 23480, 24220, 24220,
      24220, 24220, 24220, 24220, 24220, 24400, 24250, 25050, 25050, 25050,
      24550
    ].map(&:to_d)

    assert_equal expected_balances, @family.net_worth_series.data.map { |b| b[:value].amount }
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
