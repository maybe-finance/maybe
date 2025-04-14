require "test_helper"
require "ostruct"

class HoldingTest < ActiveSupport::TestCase
  include EntriesTestHelper, SecuritiesTestHelper

  setup do
    @account = families(:empty).accounts.create!(name: "Test Brokerage", balance: 20000, cash_balance: 0, currency: "USD", accountable: Investment.new)

    # Current day holding instances
    @amzn, @nvda = load_holdings
  end

  test "calculates portfolio weight" do
    expected_amzn_weight = 3240.0 / @account.balance * 100
    expected_nvda_weight = 3720.0 / @account.balance * 100

    assert_in_delta expected_amzn_weight, @amzn.weight, 0.001
    assert_in_delta expected_nvda_weight, @nvda.weight, 0.001
  end

  test "calculates simple average cost basis" do
    create_trade(@amzn.security, account: @account, qty: 10, price: 212.00, date: 1.day.ago.to_date)
    create_trade(@amzn.security, account: @account, qty: 15, price: 216.00, date: Date.current)

    create_trade(@nvda.security, account: @account, qty: 5, price: 128.00, date: 1.day.ago.to_date)
    create_trade(@nvda.security, account: @account, qty: 30, price: 124.00, date: Date.current)

    assert_equal Money.new((212.0 + 216.0) / 2), @amzn.avg_cost
    assert_equal Money.new((128.0 + 124.0) / 2), @nvda.avg_cost
  end

  test "calculates total return trend" do
    @amzn.stubs(:avg_cost).returns(Money.new(214.00))
    @nvda.stubs(:avg_cost).returns(Money.new(126.00))

    # Gained $30, or 0.93%
    assert_equal Money.new(30), @amzn.trend.value
    assert_in_delta 0.9, @amzn.trend.percent, 0.001

    # Lost $60, or -1.59%
    assert_equal Money.new(-60), @nvda.trend.value
    assert_in_delta -1.6, @nvda.trend.percent, 0.001
  end

  private

    def load_holdings
      security1 = create_security("AMZN", prices: [
        { date: 1.day.ago.to_date, price: 212.00 },
        { date: Date.current, price: 216.00 }
      ])

      security2 = create_security("NVDA", prices: [
        { date: 1.day.ago.to_date, price: 128.00 },
        { date: Date.current, price: 124.00 }
      ])

      create_holding(security1, 1.day.ago.to_date, 10)
      amzn = create_holding(security1, Date.current, 15)

      create_holding(security2, 1.day.ago.to_date, 5)
      nvda = create_holding(security2, Date.current, 30)

      [ amzn, nvda ]
    end

    def create_holding(security, date, qty)
      price = Security::Price.find_by(date: date, security: security).price

      @account.holdings.create! \
        date: date,
        security: security,
        qty: qty,
        price: price,
        amount: qty * price,
        currency: "USD"
    end
end
