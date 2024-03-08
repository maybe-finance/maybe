require "test_helper"

class Account::BalanceCalculatorTest < ActiveSupport::TestCase
    test "syncs account with only valuations" do
        account = accounts(:collectable)

        daily_balances = Account::BalanceCalculator.new(account).daily_balances

        expected_balances = [
            400, 400, 400, 400, 400, 400, 400, 400, 400, 400,
            400, 400, 400, 400, 400, 400, 400, 400, 700, 700,
            700, 700, 700, 700, 700, 700, 550, 550, 550, 550,
            550
        ].map(&:to_d)

        assert_equal expected_balances, daily_balances.map { |b| b[:balance] }
    end

    test "syncs account with only transactions" do
        account = accounts(:checking)

        daily_balances = Account::BalanceCalculator.new(account).daily_balances

        expected_balances = [
            4000, 3985, 3985, 3985, 3985, 3985, 3985, 3985, 5060, 5060,
            5060, 5060, 5060, 5060, 5060, 5040, 5040, 5040, 5010, 5010,
            5010, 5010, 5010, 5010, 5010, 5000, 5000, 5000, 5000, 5000,
            5000
        ].map(&:to_d)

        assert_equal expected_balances, daily_balances.map { |b| b[:balance] }
    end

    test "syncs account with both valuations and transactions" do
        account = accounts(:savings_with_valuation_overrides)
        daily_balances = Account::BalanceCalculator.new(account).daily_balances

        expected_balances = [
            21250, 21750, 21750, 21750, 21750, 21000, 21000, 21000, 21000, 21000,
            21000, 21000, 19000, 19000, 19000, 19000, 19000, 19000, 19500, 19500,
            19500, 19500, 19500, 19500, 19500, 19700, 19700, 20500, 20500, 20500,
            20000
        ].map(&:to_d)

        assert_equal expected_balances, daily_balances.map { |b| b[:balance] }
    end

    test "syncs liability account" do
        account = accounts(:credit_card)
        daily_balances = Account::BalanceCalculator.new(account).daily_balances

        expected_balances = [
            1040, 940, 940, 940, 940, 940, 940, 940, 940, 940,
            940, 940, 940, 940, 940, 960, 960, 960, 990, 990,
            990, 990, 990, 990, 990, 1000, 1000, 1000, 1000, 1000,
            1000
        ].map(&:to_d)

        assert_equal expected_balances, daily_balances.map { |b| b[:balance] }
    end
end
