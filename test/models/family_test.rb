require "test_helper"
require "csv"

class FamilyTest < ActiveSupport::TestCase
  include FamilySnapshotTestHelper

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
    assert_difference("Category.count", -@family.categories.count) do
      @family.destroy
    end
  end

  test "should destroy dependent merchants" do
    assert_difference("Merchant.count", -@family.merchants.count) do
      @family.destroy
    end
  end

  test "should calculate total assets" do
    expected = get_today_snapshot_value_for :assets
    assert_in_delta expected, @family.assets.amount, 0.01
  end

  test "should calculate total liabilities" do
    expected = get_today_snapshot_value_for :liabilities
    assert_in_delta expected, @family.liabilities.amount, 0.01
  end

  test "should calculate net worth" do
    expected = get_today_snapshot_value_for :net_worth
    assert_in_delta expected, @family.net_worth.amount, 0.01
  end

  test "calculates asset time series" do
    series = @family.snapshot[:asset_series]
    expected_series = get_expected_balances_for :assets

    assert_time_series_balances series, expected_series
  end

  test "calculates liability time series" do
    series = @family.snapshot[:liability_series]
    expected_series = get_expected_balances_for :liabilities

    assert_time_series_balances series, expected_series
  end

  test "calculates net worth time series" do
    series = @family.snapshot[:net_worth_series]
    expected_series = get_expected_balances_for :net_worth

    assert_time_series_balances series, expected_series
  end

  test "calculates rolling expenses" do
    series = @family.snapshot_transactions[:spending_series]
    expected_series = get_expected_balances_for :rolling_spend

    puts series.to_json

    assert_time_series_balances series, expected_series, ignore_count: true
  end

  test "calculates rolling income" do
    series = @family.snapshot_transactions[:income_series]
    expected_series = get_expected_balances_for :rolling_income

    assert_time_series_balances series, expected_series, ignore_count: true
  end

  test "calculates savings rate series" do
    series = @family.snapshot_transactions[:savings_rate_series]
    expected_series = get_expected_balances_for :savings_rate

    series.values.each do |tsb|
      expected_balance = expected_series.find { |eb| eb[:date] == tsb.date }
      assert_in_delta expected_balance[:balance], tsb.value, 0.0001, "Balance incorrect on date: #{tsb.date}"
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

  private

    def assert_time_series_balances(time_series_balances, expected_balances, ignore_count: false)
      assert_equal time_series_balances.values.count, expected_balances.count unless ignore_count

      time_series_balances.values.each do |tsb|
        expected_balance = expected_balances.find { |eb| eb[:date] == tsb.date }
        assert_in_delta expected_balance[:balance], tsb.value.amount, 0.01, "Balance incorrect on date: #{tsb.date}"
      end
    end
end
