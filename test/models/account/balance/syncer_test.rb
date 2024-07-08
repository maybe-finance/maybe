require "test_helper"
require "csv"

class Account::Balance::CalculatorTest < ActiveSupport::TestCase
  include FamilySnapshotTestHelper

  test "syncs other asset balances" do
    expected_balances = get_expected_balances_for(:collectable)
    assert_account_balances calculated_balances_for(:collectable), expected_balances
  end

  test "syncs other liability balances" do
    expected_balances = get_expected_balances_for(:iou)
    assert_account_balances calculated_balances_for(:iou), expected_balances
  end

  test "syncs credit balances" do
    expected_balances = get_expected_balances_for :credit_card
    assert_account_balances calculated_balances_for(:credit_card), expected_balances
  end

  test "syncs checking account balances" do
    expected_balances = get_expected_balances_for(:checking)
    assert_account_balances calculated_balances_for(:checking), expected_balances
  end

  test "syncs foreign checking account balances" do
    # Foreign accounts will generate balances for all currencies
    expected_usd_balances = get_expected_balances_for(:eur_checking_usd)
    expected_eur_balances = get_expected_balances_for(:eur_checking_eur)

    calculated_balances = calculated_balances_for(:eur_checking)
    calculated_usd_balances = calculated_balances.select { |b| b[:currency] == "USD" }
    calculated_eur_balances = calculated_balances.select { |b| b[:currency] == "EUR" }

    assert_account_balances calculated_usd_balances, expected_usd_balances
    assert_account_balances calculated_eur_balances, expected_eur_balances
  end

  test "syncs multi-currency checking account balances" do
    expected_balances = get_expected_balances_for(:multi_currency)
    assert_account_balances calculated_balances_for(:multi_currency), expected_balances
  end

  test "syncs savings accounts balances" do
    expected_balances = get_expected_balances_for(:savings)
    assert_account_balances calculated_balances_for(:savings), expected_balances
  end

  test "syncs investment account balances" do
    expected_balances = get_expected_balances_for(:brokerage)
    assert_account_balances calculated_balances_for(:brokerage), expected_balances
  end

  test "syncs loan account balances" do
    expected_balances = get_expected_balances_for(:mortgage_loan)
    assert_account_balances calculated_balances_for(:mortgage_loan), expected_balances
  end

  test "syncs property account balances" do
    expected_balances = get_expected_balances_for(:house)
    assert_account_balances calculated_balances_for(:house), expected_balances
  end

  test "syncs vehicle account balances" do
    expected_balances = get_expected_balances_for(:car)
    assert_account_balances calculated_balances_for(:car), expected_balances
  end

  private
    def assert_account_balances(actual_balances, expected_balances)
      assert_equal expected_balances.count, actual_balances.count

      actual_balances.each do |ab|
        expected_balance = expected_balances.find { |eb| eb[:date] == ab[:date] }
        assert_in_delta expected_balance[:balance], ab[:balance], 0.01, "Balance incorrect on date: #{ab[:date]}"
      end
    end

    def calculated_balances_for(account_key)
      Account::Balance::Calculator.new(accounts(account_key)).daily_balances
    end
end
