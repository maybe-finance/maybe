require "test_helper"
require "csv"

class Account::Balance::ManualAccountBalanceCalculatorTest < ActiveSupport::TestCase
  # See: https://docs.google.com/spreadsheets/d/18LN5N-VLq4b49Mq1fNwF7_eBiHSQB46qQduRtdAEN98/edit?usp=sharing
  setup do
    @expected_balances = CSV.read("test/fixtures/account/expected_balances.csv", headers: true).map do |row|
      {
        "date" => (Date.current + row["date_offset"].to_i.days).to_date,
        "collectable" => row["collectable"],
        "checking" => row["checking"],
        "savings_with_valuation_overrides" => row["savings_with_valuation_overrides"],
        "credit_card" => row["credit_card"],
        "multi_currency" => row["multi_currency"],

        # Balances should be calculated for all currencies of an account
        "eur_checking_eur" => row["eur_checking_eur"],
        "eur_checking_usd" => row["eur_checking_usd"]
      }
    end
  end

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
