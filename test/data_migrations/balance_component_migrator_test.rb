require "test_helper"

class BalanceComponentMigratorTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @depository = accounts(:depository)
    @investment = accounts(:investment)
    @loan = accounts(:loan)

    # Start fresh
    Balance.delete_all
  end

  test "depository account with no gaps" do
    create_balance_history(@depository, [
      { date: 5.days.ago, cash_balance: 1000, balance: 1000 },
      { date: 4.days.ago, cash_balance: 1100, balance: 1100 },
      { date: 3.days.ago, cash_balance: 1050, balance: 1050 },
      { date: 2.days.ago, cash_balance: 1200, balance: 1200 },
      { date: 1.day.ago, cash_balance: 1150, balance: 1150 }
    ])

    BalanceComponentMigrator.run

    assert_migrated_balances @depository, [
      { date: 5.days.ago, start_cash: 0, start_non_cash: 0, start: 0, cash_inflows: 1000, non_cash_inflows: 0, end_cash: 1000, end_non_cash: 0, end: 1000 },
      { date: 4.days.ago, start_cash: 1000, start_non_cash: 0, start: 1000, cash_inflows: 100, non_cash_inflows: 0, end_cash: 1100, end_non_cash: 0, end: 1100 },
      { date: 3.days.ago, start_cash: 1100, start_non_cash: 0, start: 1100, cash_inflows: -50, non_cash_inflows: 0, end_cash: 1050, end_non_cash: 0, end: 1050 },
      { date: 2.days.ago, start_cash: 1050, start_non_cash: 0, start: 1050, cash_inflows: 150, non_cash_inflows: 0, end_cash: 1200, end_non_cash: 0, end: 1200 },
      { date: 1.day.ago, start_cash: 1200, start_non_cash: 0, start: 1200, cash_inflows: -50, non_cash_inflows: 0, end_cash: 1150, end_non_cash: 0, end: 1150 }
    ]
  end

  test "depository account with gaps" do
    create_balance_history(@depository, [
      { date: 5.days.ago, cash_balance: 1000, balance: 1000 },
      { date: 1.day.ago, cash_balance: 1150, balance: 1150 }
    ])

    BalanceComponentMigrator.run

    assert_migrated_balances @depository, [
      { date: 5.days.ago, start_cash: 0, start_non_cash: 0, start: 0, cash_inflows: 1000, non_cash_inflows: 0, end_cash: 1000, end_non_cash: 0, end: 1000 },
      { date: 1.day.ago, start_cash: 1000, start_non_cash: 0, start: 1000, cash_inflows: 150, non_cash_inflows: 0, end_cash: 1150, end_non_cash: 0, end: 1150 }
    ]
  end

  test "investment account with no gaps" do
    create_balance_history(@investment, [
      { date: 3.days.ago, cash_balance: 100, balance: 200 },
      { date: 2.days.ago, cash_balance: 200, balance: 300 },
      { date: 1.day.ago, cash_balance: 0, balance: 300 }
    ])

    BalanceComponentMigrator.run

    assert_migrated_balances @investment, [
      { date: 3.days.ago, start_cash: 0, start_non_cash: 0, start: 0, cash_inflows: 100, non_cash_inflows: 100, end_cash: 100, end_non_cash: 100, end: 200 },
      { date: 2.days.ago, start_cash: 100, start_non_cash: 100, start: 200, cash_inflows: 100, non_cash_inflows: 0, end_cash: 200, end_non_cash: 100, end: 300 },
      { date: 1.day.ago, start_cash: 200, start_non_cash: 100, start: 300, cash_inflows: -200, non_cash_inflows: 200, end_cash: 0, end_non_cash: 300, end: 300 }
    ]
  end

  test "investment account with gaps" do
    create_balance_history(@investment, [
      { date: 5.days.ago, cash_balance: 1000, balance: 1000 },
      { date: 1.day.ago, cash_balance: 1150, balance: 1150 }
    ])

    BalanceComponentMigrator.run

    assert_migrated_balances @investment, [
      { date: 5.days.ago, start_cash: 0, start_non_cash: 0, start: 0, cash_inflows: 1000, non_cash_inflows: 0, end_cash: 1000, end_non_cash: 0, end: 1000 },
      { date: 1.day.ago, start_cash: 1000, start_non_cash: 0, start: 1000, cash_inflows: 150, non_cash_inflows: 0, end_cash: 1150, end_non_cash: 0, end: 1150 }
    ]
  end

  # Negative flows factor test
  test "loan account with no gaps" do
    create_balance_history(@loan, [
      { date: 3.days.ago, cash_balance: 0, balance: 200 },
      { date: 2.days.ago, cash_balance: 0, balance: 300 },
      { date: 1.day.ago, cash_balance: 0, balance: 500 }
    ])

    BalanceComponentMigrator.run

    assert_migrated_balances @loan, [
      { date: 3.days.ago, start_cash: 0, start_non_cash: 0, start: 0, cash_inflows: 0, non_cash_inflows: -200, end_cash: 0, end_non_cash: 200, end: 200 },
      { date: 2.days.ago, start_cash: 0, start_non_cash: 200, start: 200, cash_inflows: 0, non_cash_inflows: -100, end_cash: 0, end_non_cash: 300, end: 300 },
      { date: 1.day.ago, start_cash: 0, start_non_cash: 300, start: 300, cash_inflows: 0, non_cash_inflows: -200, end_cash: 0, end_non_cash: 500, end: 500 }
    ]
  end

  test "loan account with gaps" do
    create_balance_history(@loan, [
      { date: 5.days.ago, cash_balance: 0, balance: 1000 },
      { date: 1.day.ago, cash_balance: 0, balance: 2000 }
    ])

    BalanceComponentMigrator.run

    assert_migrated_balances @loan, [
      { date: 5.days.ago, start_cash: 0, start_non_cash: 0, start: 0, cash_inflows: 0, non_cash_inflows: -1000, end_cash: 0, end_non_cash: 1000, end: 1000 },
      { date: 1.day.ago, start_cash: 0, start_non_cash: 1000, start: 1000, cash_inflows: 0, non_cash_inflows: -1000, end_cash: 0, end_non_cash: 2000, end: 2000 }
    ]
  end

  private
    def create_balance_history(account, balances)
      balances.each do |balance|
        account.balances.create!(
          date: balance[:date].to_date,
          balance: balance[:balance],
          cash_balance: balance[:cash_balance],
          currency: account.currency
        )
      end
    end

    def assert_migrated_balances(account, expected)
      balances = account.balances.order(:date)

      expected.each_with_index do |expected_values, index|
        balance = balances.find { |b| b.date == expected_values[:date].to_date }
        assert balance, "Expected balance for #{expected_values[:date].to_date} but none found"

        # Assert expected values
        assert_equal expected_values[:start_cash], balance.start_cash_balance,
          "start_cash_balance mismatch for #{balance.date}"
        assert_equal expected_values[:start_non_cash], balance.start_non_cash_balance,
          "start_non_cash_balance mismatch for #{balance.date}"
        assert_equal expected_values[:start], balance.start_balance,
          "start_balance mismatch for #{balance.date}"
        assert_equal expected_values[:cash_inflows], balance.cash_inflows,
          "cash_inflows mismatch for #{balance.date}"
        assert_equal expected_values[:non_cash_inflows], balance.non_cash_inflows,
          "non_cash_inflows mismatch for #{balance.date}"
        assert_equal expected_values[:end_cash], balance.end_cash_balance,
          "end_cash_balance mismatch for #{balance.date}"
        assert_equal expected_values[:end_non_cash], balance.end_non_cash_balance,
          "end_non_cash_balance mismatch for #{balance.date}"
        assert_equal expected_values[:end], balance.end_balance,
          "end_balance mismatch for #{balance.date}"

        # Assert zeros for other fields
        assert_equal 0, balance.cash_outflows,
          "cash_outflows should be zero for #{balance.date}"
        assert_equal 0, balance.non_cash_outflows,
          "non_cash_outflows should be zero for #{balance.date}"
        assert_equal 0, balance.cash_adjustments,
          "cash_adjustments should be zero for #{balance.date}"
        assert_equal 0, balance.non_cash_adjustments,
          "non_cash_adjustments should be zero for #{balance.date}"
        assert_equal 0, balance.net_market_flows,
          "net_market_flows should be zero for #{balance.date}"
      end
    end
end
