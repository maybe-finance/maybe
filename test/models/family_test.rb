require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  def setup
    @family = families(:dylan_family)
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
    @family.accounts.each do |account|
      account.sync
    end

    # Sum of expected balances for all asset accounts in balance_calculator_test.rb
    expected_balances = [
      25650, 26135, 26135, 26135, 26135, 25385, 25385, 25385, 26460, 26460,
      26460, 26460, 24460, 24460, 24460, 24440, 24440, 24440, 25210, 25210,
      25210, 25210, 25210, 25210, 25210, 25400, 25250, 26050, 26050, 26050,
      26000,
    ].map(&:to_d)

    assert_equal expected_balances, @family.asset_series.map { |b| b[:balance] }
  end

end
