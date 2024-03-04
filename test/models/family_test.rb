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
    result = @family.balances_by_type

    assets_result = result["asset"].map { |a| a.except(:trend) }
    liabilities_result = result["liability"].map { |a| a.except(:trend) }

    expected_assets = [
      { accountable_type: "Account::Depository", current: BigDecimal("25000"), previous: BigDecimal("25250") },
      { accountable_type: "Account::OtherAsset", current: BigDecimal("550"), previous: BigDecimal("400") }
    ]

    expected_liabilities = [
      { accountable_type: "Account::Credit", current: BigDecimal("1000"), previous: BigDecimal("1040") }
    ]

    assert_equal expected_assets, assets_result
    assert_equal expected_liabilities, liabilities_result
  end

  test "calculates balances by type with date range filter" do
    period = Period.find_by_name("last_7_days")
    result = @family.balances_by_type(period)

    assets_result = result["asset"].map { |a| a.except(:trend) }
    liabilities_result = result["liability"].map { |a| a.except(:trend) }

    expected_assets = [
      { accountable_type: "Account::Depository", current: BigDecimal("25000"), previous: BigDecimal("24510") },
      { accountable_type: "Account::OtherAsset", current: BigDecimal("550"), previous: BigDecimal("700") }
    ]

    expected_liabilities = [
      { accountable_type: "Account::Credit", current: BigDecimal("1000"), previous: BigDecimal("990") }
    ]

    assert_equal expected_assets, assets_result
    assert_equal expected_liabilities, liabilities_result
  end
end
