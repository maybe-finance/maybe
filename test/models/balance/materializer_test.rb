require "test_helper"

class Balance::MaterializerTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(
      name: "Test",
      balance: 20000,
      cash_balance: 20000,
      currency: "USD",
      accountable: Investment.new
    )
  end

  test "syncs balances" do
    Holding::Materializer.any_instance.expects(:materialize_holdings).returns([]).once

    @account.expects(:start_date).returns(2.days.ago.to_date)

    expected_balances = [
      Balance.new(
        date: 1.day.ago.to_date,
        balance: 1000,
        cash_balance: 1000,
        currency: "USD",
        start_cash_balance: 500,
        start_non_cash_balance: 0,
        cash_inflows: 500,
        cash_outflows: 0,
        non_cash_inflows: 0,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
        flows_factor: 1
      ),
      Balance.new(
        date: Date.current,
        balance: 1000,
        cash_balance: 1000,
        currency: "USD",
        start_cash_balance: 1000,
        start_non_cash_balance: 0,
        cash_inflows: 0,
        cash_outflows: 0,
        non_cash_inflows: 0,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
        flows_factor: 1
      )
    ]

    Balance::ForwardCalculator.any_instance.expects(:calculate).returns(expected_balances)

    assert_difference "@account.balances.count", 2 do
      Balance::Materializer.new(@account, strategy: :forward).materialize_balances
    end

    assert_balance_fields_persisted(expected_balances)
  end

  test "purges stale balances and holdings" do
    # Balance before start date is stale
    @account.expects(:start_date).returns(2.days.ago.to_date).twice
    
    stale_balance = Balance.new(
      date: 3.days.ago.to_date,
      balance: 10000,
      cash_balance: 10000,
      currency: "USD",
      start_cash_balance: 0,
      start_non_cash_balance: 0,
      cash_inflows: 0,
      cash_outflows: 0,
      non_cash_inflows: 0,
      non_cash_outflows: 0,
      net_market_flows: 0,
      cash_adjustments: 10000,
      non_cash_adjustments: 0,
      flows_factor: 1
    )

    expected_balances = [
      stale_balance,
      Balance.new(
        date: 2.days.ago.to_date,
        balance: 10000,
        cash_balance: 10000,
        currency: "USD",
        start_cash_balance: 10000,
        start_non_cash_balance: 0,
        cash_inflows: 0,
        cash_outflows: 0,
        non_cash_inflows: 0,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
        flows_factor: 1
      ),
      Balance.new(
        date: 1.day.ago.to_date,
        balance: 1000,
        cash_balance: 1000,
        currency: "USD",
        start_cash_balance: 10000,
        start_non_cash_balance: 0,
        cash_inflows: 0,
        cash_outflows: 9000,
        non_cash_inflows: 0,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
        flows_factor: 1
      ),
      Balance.new(
        date: Date.current,
        balance: 1000,
        cash_balance: 1000,
        currency: "USD",
        start_cash_balance: 1000,
        start_non_cash_balance: 0,
        cash_inflows: 0,
        cash_outflows: 0,
        non_cash_inflows: 0,
        non_cash_outflows: 0,
        net_market_flows: 0,
        cash_adjustments: 0,
        non_cash_adjustments: 0,
        flows_factor: 1
      )
    ]

    Balance::ForwardCalculator.any_instance.expects(:calculate).returns(expected_balances)

    assert_difference "@account.balances.count", 3 do
      Balance::Materializer.new(@account, strategy: :forward).materialize_balances
    end

    # Only non-stale balances should be persisted and checked
    assert_balance_fields_persisted(expected_balances.reject { |b| b.date < 2.days.ago.to_date })
  end

  private

  def assert_balance_fields_persisted(expected_balances)
    expected_balances.each do |expected|
      persisted = @account.balances.find_by(date: expected.date)
      assert_not_nil persisted, "Balance for #{expected.date} should be persisted"
      
      # Check all balance component fields
      assert_equal expected.balance, persisted.balance
      assert_equal expected.cash_balance, persisted.cash_balance
      assert_equal expected.start_cash_balance, persisted.start_cash_balance
      assert_equal expected.start_non_cash_balance, persisted.start_non_cash_balance
      assert_equal expected.cash_inflows, persisted.cash_inflows
      assert_equal expected.cash_outflows, persisted.cash_outflows
      assert_equal expected.non_cash_inflows, persisted.non_cash_inflows
      assert_equal expected.non_cash_outflows, persisted.non_cash_outflows
      assert_equal expected.net_market_flows, persisted.net_market_flows
      assert_equal expected.cash_adjustments, persisted.cash_adjustments
      assert_equal expected.non_cash_adjustments, persisted.non_cash_adjustments
      assert_equal expected.flows_factor, persisted.flows_factor
    end
  end
end
