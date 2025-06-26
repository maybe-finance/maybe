require "test_helper"

class Holding::ReverseCalculatorTest < ActiveSupport::TestCase
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

  test "no holdings" do
    empty_snapshot = OpenStruct.new(to_h: {})
    calculated = Holding::ReverseCalculator.new(@account, portfolio_snapshot: empty_snapshot).calculate
    assert_equal [], calculated
  end

  test "holding generation respects user timezone and last generated date is current user date" do
    # Simulate user in EST timezone
    Time.use_zone("America/New_York") do
      # Set current time to 1am UTC on Jan 5, 2025
      # This would be 8pm EST on Jan 4, 2025 (user's time, and the last date we should generate holdings for)
      travel_to Time.utc(2025, 01, 05, 1, 0, 0)

      voo = Security.create!(ticker: "VOO", name: "Vanguard S&P 500 ETF")
      Security::Price.create!(security: voo, date: "2025-01-02", price: 500)
      Security::Price.create!(security: voo, date: "2025-01-03", price: 500)
      Security::Price.create!(security: voo, date: "2025-01-04", price: 500)

      # Today's holdings (provided)
      @account.holdings.create!(security: voo, date: "2025-01-04", qty: 10, price: 500, amount: 5000, currency: "USD")

      create_trade(voo, qty: 10, date: "2025-01-03", price: 500, account: @account)

      expected = [ [ "2025-01-02", 0 ], [ "2025-01-03", 5000 ], [ "2025-01-04", 5000 ] ]
      # Mock snapshot with the holdings we created
      snapshot = OpenStruct.new(to_h: { voo.id => 10 })
      calculated = Holding::ReverseCalculator.new(@account, portfolio_snapshot: snapshot).calculate

      assert_equal expected, calculated.sort_by(&:date).map { |b| [ b.date.to_s, b.amount ] }
    end
  end

  # Should be able to handle this case, although we should not be reverse-syncing an account without provided current day holdings
  test "reverse portfolio with trades but without current day holdings" do
    voo = Security.create!(ticker: "VOO", name: "Vanguard S&P 500 ETF")
    Security::Price.create!(security: voo, date: Date.current, price: 470)
    Security::Price.create!(security: voo, date: 1.day.ago.to_date, price: 470)

    create_trade(voo, qty: -10, date: Date.current, price: 470, account: @account)

    # Mock empty portfolio since no current day holdings
    snapshot = OpenStruct.new(to_h: { voo.id => 0 })
    calculated = Holding::ReverseCalculator.new(@account, portfolio_snapshot: snapshot).calculate
    assert_equal 2, calculated.length
  end

  test "reverse portfolio calculation" do
    load_today_portfolio

    # Build up to 10 shares of VOO (current value $5000)
    create_trade(@voo, qty: 20, date: 3.days.ago.to_date, price: 470, account: @account)
    create_trade(@voo, qty: -15, date: 2.days.ago.to_date, price: 480, account: @account)
    create_trade(@voo, qty: 5, date: 1.day.ago.to_date, price: 490, account: @account)

    # Amazon won't exist in current holdings because qty is zero, but should show up in historical portfolio
    create_trade(@amzn, qty: 1, date: 2.days.ago.to_date, price: 200, account: @account)
    create_trade(@amzn, qty: -1, date: 1.day.ago.to_date, price: 200, account: @account)

    # Build up to 100 shares of WMT (current value $10000)
    create_trade(@wmt, qty: 100, date: 1.day.ago.to_date, price: 100, account: @account)

    expected = [
      # 4 days ago
      Holding.new(security: @voo, date: 4.days.ago.to_date, qty: 0, price: 460, amount: 0),
      Holding.new(security: @wmt, date: 4.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Holding.new(security: @amzn, date: 4.days.ago.to_date, qty: 0, price: 200, amount: 0),

      # 3 days ago
      Holding.new(security: @voo, date: 3.days.ago.to_date, qty: 20, price: 470, amount: 9400),
      Holding.new(security: @wmt, date: 3.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Holding.new(security: @amzn, date: 3.days.ago.to_date, qty: 0, price: 200, amount: 0),

      # 2 days ago
      Holding.new(security: @voo, date: 2.days.ago.to_date, qty: 5, price: 480, amount: 2400),
      Holding.new(security: @wmt, date: 2.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Holding.new(security: @amzn, date: 2.days.ago.to_date, qty: 1, price: 200, amount: 200),

      # 1 day ago
      Holding.new(security: @voo, date: 1.day.ago.to_date, qty: 10, price: 490, amount: 4900),
      Holding.new(security: @wmt, date: 1.day.ago.to_date, qty: 100, price: 100, amount: 10000),
      Holding.new(security: @amzn, date: 1.day.ago.to_date, qty: 0, price: 200, amount: 0),

      # Today
      Holding.new(security: @voo, date: Date.current, qty: 10, price: 500, amount: 5000),
      Holding.new(security: @wmt, date: Date.current, qty: 100, price: 100, amount: 10000),
      Holding.new(security: @amzn, date: Date.current, qty: 0, price: 200, amount: 0)
    ]

    # Mock snapshot with today's portfolio from load_today_portfolio
    snapshot = OpenStruct.new(to_h: { @voo.id => 10, @wmt.id => 100, @amzn.id => 0 })
    calculated = Holding::ReverseCalculator.new(@account, portfolio_snapshot: snapshot).calculate

    assert_equal expected.length, calculated.length

    expected.each do |expected_entry|
      calculated_entry = calculated.find { |c| c.security == expected_entry.security && c.date == expected_entry.date }

      assert_equal expected_entry.qty, calculated_entry.qty, "Qty mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
      assert_equal expected_entry.price, calculated_entry.price, "Price mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
      assert_equal expected_entry.amount, calculated_entry.amount, "Amount mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
    end
  end

  # For a reverse sync, Plaid will provide today's holdings + prices.  We need to match those exactly so balances match in net worth rollups.
  test "current day holdings always match provided holdings and prices" do
    # Provider gives us total value of $10,000 ($5,000 cash, $5,000 in holdings)
    @account.update!(balance: 10000, cash_balance: 5000)

    wmt = Security.create!(ticker: "WMT", name: "Walmart Inc.")
    create_trade(wmt, qty: 50, date: 1.day.ago.to_date, price: 98, account: @account)

    @account.holdings.create!(
      date: Date.current,
      price: 100,
      qty: 50,
      amount: 5000,
      currency: "USD",
      security: wmt
    )

    Security::Price.create!(security: wmt, date: Date.current, price: 102) # This price should be ignored on current day
    Security::Price.create!(security: wmt, date: 1.day.ago, price: 98) # This price will be used for historical holding calculation
    Security::Price.create!(security: wmt, date: 2.days.ago, price: 95) # This price will be used for historical holding calculation

    expected = [
      Holding.new(security: wmt, date: 2.days.ago.to_date, qty: 0, price: 95, amount: 0), # Uses market price, empty holding
      Holding.new(security: wmt, date: 1.day.ago.to_date, qty: 50, price: 98, amount: 4900), # Uses market price
      Holding.new(security: wmt, date: Date.current, qty: 50, price: 100, amount: 5000) # Uses holding price, not market price
    ]

    # Mock snapshot with WMT holding from the test setup
    snapshot = OpenStruct.new(to_h: { wmt.id => 50 })
    calculated = Holding::ReverseCalculator.new(@account, portfolio_snapshot: snapshot).calculate

    assert_equal expected.length, calculated.length

    expected.each do |expected_entry|
      calculated_entry = calculated.find { |c| c.security == expected_entry.security && c.date == expected_entry.date }

      assert_equal expected_entry.qty, calculated_entry.qty, "Qty mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
      assert_equal expected_entry.price, calculated_entry.price, "Price mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
      assert_equal expected_entry.amount, calculated_entry.amount, "Amount mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
    end
  end

  private
    def assert_holdings(expected, calculated)
      expected.each do |expected_entry|
        calculated_entry = calculated.find { |c| c.security == expected_entry.security && c.date == expected_entry.date }

        assert_equal expected_entry.qty, calculated_entry.qty, "Qty mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
        assert_equal expected_entry.price, calculated_entry.price, "Price mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
        assert_equal expected_entry.amount, calculated_entry.amount, "Amount mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
      end
    end

    def load_prices
      @voo = Security.create!(ticker: "VOO", name: "Vanguard S&P 500 ETF")
      Security::Price.create!(security: @voo, date: 4.days.ago.to_date, price: 460)
      Security::Price.create!(security: @voo, date: 3.days.ago.to_date, price: 470)
      Security::Price.create!(security: @voo, date: 2.days.ago.to_date, price: 480)
      Security::Price.create!(security: @voo, date: 1.day.ago.to_date, price: 490)
      Security::Price.create!(security: @voo, date: Date.current, price: 500)

      @wmt = Security.create!(ticker: "WMT", name: "Walmart Inc.")
      Security::Price.create!(security: @wmt, date: 4.days.ago.to_date, price: 100)
      Security::Price.create!(security: @wmt, date: 3.days.ago.to_date, price: 100)
      Security::Price.create!(security: @wmt, date: 2.days.ago.to_date, price: 100)
      Security::Price.create!(security: @wmt, date: 1.day.ago.to_date, price: 100)
      Security::Price.create!(security: @wmt, date: Date.current, price: 100)

      @amzn = Security.create!(ticker: "AMZN", name: "Amazon.com Inc.")
      Security::Price.create!(security: @amzn, date: 4.days.ago.to_date, price: 200)
      Security::Price.create!(security: @amzn, date: 3.days.ago.to_date, price: 200)
      Security::Price.create!(security: @amzn, date: 2.days.ago.to_date, price: 200)
      Security::Price.create!(security: @amzn, date: 1.day.ago.to_date, price: 200)
      Security::Price.create!(security: @amzn, date: Date.current, price: 200)
    end

    # Portfolio holdings:
    # +--------+-----+--------+---------+
    # | Ticker | Qty | Price  | Amount  |
    # +--------+-----+--------+---------+
    # | VOO    |  10 | $500   | $5,000  |
    # | WMT    | 100 | $100   | $10,000 |
    # +--------+-----+--------+---------+
    # Brokerage Cash: $5,000
    # Holdings Value: $15,000
    # Total Balance: $20,000
    def load_today_portfolio
      @account.update!(cash_balance: 5000)

      load_prices

      @account.holdings.create!(
        date: Date.current,
        price: 500,
        qty: 10,
        amount: 5000,
        currency: "USD",
        security: @voo
      )

      @account.holdings.create!(
        date: Date.current,
        price: 100,
        qty: 100,
        amount: 10000,
        currency: "USD",
        security: @wmt
      )
    end
end
