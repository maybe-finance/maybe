require "test_helper"
require "csv"

class Account::Balance::CalculatorTest < ActiveSupport::TestCase
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

    test "syncs account with only valuations" do
        account = accounts(:collectable)

        calculator = Account::Balance::Calculator.new(account)
        calculator.calculate

        expected = @expected_balances.map { |row| row["collectable"].to_d }
        actual = calculator.daily_balances.map { |b| b[:balance] }

        assert_equal expected, actual
    end

    test "syncs account with only transactions" do
        account = accounts(:checking)

        calculator = Account::Balance::Calculator.new(account)
        calculator.calculate

        expected = @expected_balances.map { |row| row["checking"].to_d }
        actual = calculator.daily_balances.map { |b| b[:balance] }

        assert_equal expected, actual
    end

    test "syncs account with both valuations and transactions" do
        account = accounts(:savings_with_valuation_overrides)

        calculator = Account::Balance::Calculator.new(account)
        calculator.calculate

        expected = @expected_balances.map { |row| row["savings_with_valuation_overrides"].to_d }
        actual = calculator.daily_balances.map { |b| b[:balance] }

        assert_equal expected, actual
    end

    test "syncs liability account" do
        account = accounts(:credit_card)

        calculator = Account::Balance::Calculator.new(account)
        calculator.calculate

        expected = @expected_balances.map { |row| row["credit_card"].to_d }
        actual = calculator.daily_balances.map { |b| b[:balance] }

        assert_equal expected, actual
    end

    test "syncs foreign currency account" do
        account = accounts(:eur_checking)
        calculator = Account::Balance::Calculator.new(account)
        calculator.calculate

        # Calculator should calculate balances in both account and family currency
        expected_eur_balances = @expected_balances.map { |row| row["eur_checking_eur"].to_d }
        expected_usd_balances = @expected_balances.map { |row| row["eur_checking_usd"].to_d }

        actual_eur_balances = calculator.daily_balances.select { |b| b[:currency] == "EUR" }.sort_by { |b| b[:date] }.map { |b| b[:balance] }
        actual_usd_balances = calculator.daily_balances.select { |b| b[:currency] == "USD" }.sort_by { |b| b[:date] }.map { |b| b[:balance] }

        assert_equal expected_eur_balances, actual_eur_balances
        assert_equal expected_usd_balances, actual_usd_balances
    end

    test "syncs multi currency account" do
        account = accounts(:multi_currency)
        calculator = Account::Balance::Calculator.new(account)
        calculator.calculate

        expected_balances = @expected_balances.map { |row| row["multi_currency"].to_d }

        actual_balances = calculator.daily_balances.map { |b| b[:balance] }

        assert_equal expected_balances, actual_balances
    end

    test "syncs with overridden start date" do
        account = accounts(:multi_currency)
        calc_start_date = 10.days.ago.to_date
        calculator = Account::Balance::Calculator.new(account, { calc_start_date: })
        calculator.calculate

        expected_balances = @expected_balances.filter { |row| row["date"] >= calc_start_date }.map { |row| row["multi_currency"].to_d }

        actual_balances = calculator.daily_balances.map { |b| b[:balance] }

        assert_equal expected_balances, actual_balances
    end
end
