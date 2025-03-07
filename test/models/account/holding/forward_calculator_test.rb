require "test_helper"

class Account::Holding::ForwardCalculatorTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

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
    calculated = Account::Holding::ForwardCalculator.new(@account).calculate
    assert_equal [], calculated
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
      Account::Holding.new(security: @voo, date: 4.days.ago.to_date, qty: 0, price: 460, amount: 0),
      Account::Holding.new(security: @wmt, date: 4.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Account::Holding.new(security: @amzn, date: 4.days.ago.to_date, qty: 0, price: 200, amount: 0),

      # 3 days ago
      Account::Holding.new(security: @voo, date: 3.days.ago.to_date, qty: 20, price: 470, amount: 9400),
      Account::Holding.new(security: @wmt, date: 3.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Account::Holding.new(security: @amzn, date: 3.days.ago.to_date, qty: 0, price: 200, amount: 0),

      # 2 days ago
      Account::Holding.new(security: @voo, date: 2.days.ago.to_date, qty: 5, price: 480, amount: 2400),
      Account::Holding.new(security: @wmt, date: 2.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Account::Holding.new(security: @amzn, date: 2.days.ago.to_date, qty: 1, price: 200, amount: 200),

      # 1 day ago
      Account::Holding.new(security: @voo, date: 1.day.ago.to_date, qty: 10, price: 490, amount: 4900),
      Account::Holding.new(security: @wmt, date: 1.day.ago.to_date, qty: 100, price: 100, amount: 10000),
      Account::Holding.new(security: @amzn, date: 1.day.ago.to_date, qty: 0, price: 200, amount: 0),

      # Today
      Account::Holding.new(security: @voo, date: Date.current, qty: 10, price: 500, amount: 5000),
      Account::Holding.new(security: @wmt, date: Date.current, qty: 100, price: 100, amount: 10000),
      Account::Holding.new(security: @amzn, date: Date.current, qty: 0, price: 200, amount: 0)
    ]

    calculated = Account::Holding::ForwardCalculator.new(@account).calculate

    assert_equal expected.length, calculated.length
    assert_holdings(expected, calculated)
  end

  # Carries the previous record forward if no holding exists for a date
  # to ensure that net worth historical rollups have a value for every date
  test "uses locf to fill missing holdings" do
    load_prices

    create_trade(@wmt, qty: 100, date: 1.day.ago.to_date, price: 100, account: @account)

    expected = [
      Account::Holding.new(security: @wmt, date: 2.days.ago.to_date, qty: 0, price: 100, amount: 0),
      Account::Holding.new(security: @wmt, date: 1.day.ago.to_date, qty: 100, price: 100, amount: 10000),
      Account::Holding.new(security: @wmt, date: Date.current, qty: 100, price: 100, amount: 10000)
    ]

    # Price missing today, so we should carry forward the holding from 1 day ago
    Security.stubs(:find).returns(@wmt)
    Security::Price.stubs(:find_price).with(security: @wmt, date: 2.days.ago.to_date).returns(Security::Price.new(price: 100))
    Security::Price.stubs(:find_price).with(security: @wmt, date: 1.day.ago.to_date).returns(Security::Price.new(price: 100))
    Security::Price.stubs(:find_price).with(security: @wmt, date: Date.current).returns(nil)

    calculated = Account::Holding::ForwardCalculator.new(@account).calculate

    assert_equal expected.length, calculated.length
    assert_holdings(expected, calculated)
  end

  test "offline tickers sync holdings based on most recent trade price" do
    offline_security = Security.create!(ticker: "OFFLINE", name: "Offline Ticker")

    create_trade(offline_security, qty: 1, date: 3.days.ago.to_date, price: 90, account: @account)
    create_trade(offline_security, qty: 1, date: 1.day.ago.to_date, price: 100, account: @account)

    expected = [
      Account::Holding.new(security: offline_security, date: 3.days.ago.to_date, qty: 1, price: 90, amount: 90),
      Account::Holding.new(security: offline_security, date: 2.days.ago.to_date, qty: 1, price: 90, amount: 90),
      Account::Holding.new(security: offline_security, date: 1.day.ago.to_date, qty: 2, price: 100, amount: 200),
      Account::Holding.new(security: offline_security, date: Date.current, qty: 2, price: 100, amount: 200)
    ]

    calculated = Account::Holding::ForwardCalculator.new(@account).calculate

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
