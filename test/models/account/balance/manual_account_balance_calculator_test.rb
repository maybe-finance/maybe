require "test_helper"
require "csv"

class Account::Balance::ManualAccountBalanceCalculatorTest < ActiveSupport::TestCase
  test "calculates current balance of a manual account with transactions" do
    account = accounts(:manual)

    calculator = Account::Balance::ManualAccountBalanceCalculator.new(account)
    balance = calculator.calculate_current_balance

    assert_equal 245, balance
  end

  test "calculates current balance of a manual account with transactions and valuations" do
    account = accounts(:manual_with_valuation_overrides)

    calculator = Account::Balance::ManualAccountBalanceCalculator.new(account)
    balance = calculator.calculate_current_balance

    assert_equal 495, balance
  end
end
