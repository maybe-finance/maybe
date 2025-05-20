require "test_helper"

class Holding::ForwardCalculatorTest < ActiveSupport::TestCase
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
    calculated = Holding::ForwardCalculator.new(@account).calculate
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
      create_trade(voo, qty: 10, date: "2025-01-03", price: 500, account: @account)

      expected = [ [ "2025-01-02", 0 ], [ "2025-01-03", 5000 ], [ "2025-01-04", 5000 ] ]
      calculated = Holding::ForwardCalculator.new(@account).calculate

      assert_equal expected, calculated.map { |b| [ b.date.to_s, b.amount ] }
    end
  end

  test "forward portfolio calculation" do
    load_prices

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

    calculated = Holding::ForwardCalculator.new(@account).calculate

    assert_equal expected.length, calculated.length
    assert_holdings(expected, calculated)
  end

  # Carries the previous record forward if no holding exists for a date
  # to ensure that net worth historical rollups have a value for every date
  test "uses locf to fill missing holdings" do
    load_prices

    create_trade(@wmt, qty: 100, date: 1.day.ago.to_date, price: 100, account: @account)

    expected = [
      Holding.new(security: @wmt, date: 2.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Holding.new(security: @wmt, date: 1.day.ago.to_date, qty: 100, price: 100, amount: 10000),
      Holding.new(security: @wmt, date: Date.current, qty: 100, price: 100, amount: 10000)
    ]

    # Price missing today, so we should carry forward the holding from 1 day ago
    Security.stubs(:find).returns(@wmt)
    Security::Price.stubs(:find_price).with(security: @wmt, date: 2.days.ago.to_date).returns(Security::Price.new(price: 100))
    Security::Price.stubs(:find_price).with(security: @wmt, date: 1.day.ago.to_date).returns(Security::Price.new(price: 100))
    Security::Price.stubs(:find_price).with(security: @wmt, date: Date.current).returns(nil)

    calculated = Holding::ForwardCalculator.new(@account).calculate

    assert_equal expected.length, calculated.length
    assert_holdings(expected, calculated)
  end

  test "offline tickers sync holdings based on most recent trade price" do
    offline_security = Security.create!(ticker: "OFFLINE", name: "Offline Ticker")

    create_trade(offline_security, qty: 1, date: 3.days.ago.to_date, price: 90, account: @account)
    create_trade(offline_security, qty: 1, date: 1.day.ago.to_date, price: 100, account: @account)

    expected = [
      Holding.new(security: offline_security, date: 3.days.ago.to_date, qty: 1, price: 90, amount: 90),
      Holding.new(security: offline_security, date: 2.days.ago.to_date, qty: 1, price: 90, amount: 90),
      Holding.new(security: offline_security, date: 1.day.ago.to_date, qty: 2, price: 100, amount: 200),
      Holding.new(security: offline_security, date: Date.current, qty: 2, price: 100, amount: 200)
    ]

    calculated = Holding::ForwardCalculator.new(@account).calculate

    assert_equal expected.length, calculated.length
    assert_holdings(expected, calculated)
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
end
