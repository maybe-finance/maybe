require "test_helper"

class Balance::ReverseCalculatorTest < ActiveSupport::TestCase
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

  # When syncing backwards, we start with the account balance and generate everything from there.
  test "no entries sync" do
    assert_equal 0, @account.balances.count

    expected = [ @account.balance, @account.balance ]
    calculated = Balance::ReverseCalculator.new(@account).calculate

    assert_equal expected, calculated.map(&:balance)
  end

  test "valuations sync" do
    create_valuation(account: @account, date: 4.days.ago.to_date, amount: 17000)
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 19000)

    expected = [ 17000, 17000, 19000, 19000, 20000, 20000 ]
    calculated = Balance::ReverseCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "transactions sync" do
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500) # income
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: 100) # expense

    expected = [ 19600, 20100, 20100, 20000, 20000, 20000 ]
    calculated = Balance::ReverseCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "multi-entry sync" do
    create_transaction(account: @account, date: 8.days.ago.to_date, amount: -5000)
    create_valuation(account: @account, date: 6.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 6.days.ago.to_date, amount: -500)
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500)
    create_valuation(account: @account, date: 3.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: 100)

    expected = [ 12000, 17000, 17000, 17000, 16500, 17000, 17000, 20100, 20000, 20000 ]
    calculated = Balance::ReverseCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  # When syncing backwards, trades from the past should NOT affect the current balance or previous balances.
  # They should only affect the *cash* component of the historical balances
  test "holdings and trades sync" do
    aapl = securities(:aapl)

    # Account starts with $20,000 total value, $19,000 cash, $1,000 in holdings
    @account.update!(cash_balance: 19000, balance: 20000)

    # Bought 10 AAPL shares 1 day ago, so cash is $19,000, $1,000 in holdings, total value is $20,000
    create_trade(aapl, account: @account, qty: 10, date: 1.day.ago.to_date, price: 100)

    Holding.create!(date: Date.current, account: @account, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")
    Holding.create!(date: 1.day.ago.to_date, account: @account, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")

    # Given constant prices, overall balance (account value) should be constant
    # (the single trade doesn't affect balance; it just alters cash vs. holdings composition)
    expected = [ 20000, 20000, 20000 ]
    calculated = Balance::ReverseCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  # A common scenario with Plaid is they'll give us holding records for today, but no trade history for some of them.
  # This is because they only supply 2 years worth of historical data.  Our system must properly handle this.
  test "properly calculates balances when a holding has no trade history" do
    aapl = securities(:aapl)
    msft = securities(:msft)

    # Account starts with $20,000 total value, $19,000 cash, $1,000 in holdings ($500 AAPL, $500 MSFT)
    @account.update!(cash_balance: 19000, balance: 20000)

    # A holding *with* trade history (5 shares of AAPL, purchased 1 day ago, results in 2 holdings)
    Holding.create!(date: Date.current, account: @account, security: aapl, qty: 5, price: 100, amount: 500, currency: "USD")
    Holding.create!(date: 1.day.ago.to_date, account: @account, security: aapl, qty: 5, price: 100, amount: 500, currency: "USD")
    create_trade(aapl, account: @account, qty: 5, date: 1.day.ago.to_date, price: 100)

    # A holding *without* trade history (5 shares of MSFT, no trade history, results in 1 holding)
    # We assume if no history is provided, this holding has existed since beginning of account
    Holding.create!(date: Date.current, account: @account, security: msft, qty: 5, price: 100, amount: 500, currency: "USD")
    Holding.create!(date: 1.day.ago.to_date, account: @account, security: msft, qty: 5, price: 100, amount: 500, currency: "USD")
    Holding.create!(date: 2.days.ago.to_date, account: @account, security: msft, qty: 5, price: 100, amount: 500, currency: "USD")

    expected = [ 20000, 20000, 20000 ]
    calculated = Balance::ReverseCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end
end
