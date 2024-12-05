require "test_helper"

class Account::ReversePortfolioCalculatorTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(
      name: "Test",
      balance: 20000,
      currency: "USD",
      accountable: Investment.new(
        cash_balance: 20000,
        holdings_balance: 0 
      )
    )
  end

  test "no holdings" do 
    calculated = Account::ReversePortfolioCalculator.new(@account).calculate
    assert_equal [], calculated
  end

  # Could happen if Plaid provides us holdings, but the trades corresponding to those are older than Plaid's max history,
  # causing an empty array of trades. In this case, just show holdings as-is.
  test "holdings but no trades" do 
    load_today_portfolio

    calculated = Account::ReversePortfolioCalculator.new(@account).calculate
    assert_equal 2, calculated.length
  end

  # Should be able to handle this case, although we should not be reverse-syncing an account without provided current day holdings
  test "no holdings with trades" do 
    voo = Security.create!(ticker: "VOO", name: "Vanguard S&P 500 ETF")
    Security::Price.create!(security: voo, date: Date.current, price: 470) 
    Security::Price.create!(security: voo, date: 1.day.ago.to_date, price: 470) 

    create_trade(voo, qty: -10, date: Date.current, price: 470, account: @account)

    calculated = Account::ReversePortfolioCalculator.new(@account).calculate
    assert_equal 2, calculated.length
  end

  test "builds historical portfolio from trades" do 
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

    calculated = Account::ReversePortfolioCalculator.new(@account).calculate

    assert_equal expected.length, calculated.length

    expected.each do |expected_entry|
      calculated_entry = calculated.find { |c| c.security == expected_entry.security && c.date == expected_entry.date }

      assert_equal expected_entry.qty, calculated_entry.qty, "Qty mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
      assert_equal expected_entry.price, calculated_entry.price, "Price mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
      assert_equal expected_entry.amount, calculated_entry.amount, "Amount mismatch for #{expected_entry.security.ticker} on #{expected_entry.date}"
    end
  end

  private
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
      @account.investment.update!(holdings_balance: 15000, cash_balance: 5000)

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

