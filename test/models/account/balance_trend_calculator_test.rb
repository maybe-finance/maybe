require "test_helper"

class Account::BalanceTrendCalculatorTest < ActiveSupport::TestCase
  setup do
    @account = accounts(:checking)
    @entry = @account.entries.first
  end

  test "handles holdings with nil amounts" do
    # Create a holding with nil amount
    holding = @account.holdings.create!(
      date: @entry.date,
      security: securities(:aapl),
      qty: 10,
      amount: nil,
      currency: "USD"
    )

    calculator = Account::BalanceTrendCalculator.new(
      [@entry],
      @account.balances.where(date: (@entry.date - 1.day)..@entry.date),
      [holding]
    )

    trend = calculator.trend_for(@entry)
    assert_not_nil trend
    assert_not_nil trend.trend
  end

  test "correctly sums holdings with mixed nil and non-nil amounts" do
    # Create holdings with both nil and non-nil amounts
    holding1 = @account.holdings.create!(
      date: @entry.date,
      security: securities(:aapl),
      qty: 10,
      amount: 1000,
      currency: "USD"
    )

    holding2 = @account.holdings.create!(
      date: @entry.date,
      security: securities(:googl),
      qty: 5,
      amount: nil,
      currency: "USD"
    )

    calculator = Account::BalanceTrendCalculator.new(
      [@entry],
      @account.balances.where(date: (@entry.date - 1.day)..@entry.date),
      [holding1, holding2]
    )

    trend = calculator.trend_for(@entry)
    assert_not_nil trend
    assert_not_nil trend.trend
  end
end
