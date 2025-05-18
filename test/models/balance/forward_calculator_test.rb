require "test_helper"

class Balance::ForwardCalculatorTest < ActiveSupport::TestCase
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

  test "balance generation respects user timezone and last generated date is current user date" do
    # Simulate user in EST timezone
    Time.use_zone("America/New_York") do
      # Set current time to 1am UTC on Jan 5, 2025
      # This would be 8pm EST on Jan 4, 2025 (user's time, and the last date we should generate balances for)
      travel_to Time.utc(2025, 01, 05, 1, 0, 0)

      # Create a valuation for Jan 3, 2025
      create_valuation(account: @account, date: "2025-01-03", amount: 17000)

      expected = [ [ "2025-01-02", 0 ], [ "2025-01-03", 17000 ], [ "2025-01-04", 17000 ] ]
      calculated = Balance::ForwardCalculator.new(@account).calculate

      assert_equal expected, calculated.map { |b| [ b.date.to_s, b.balance ] }
    end
  end

  # When syncing forwards, we don't care about the account balance.  We generate everything based on entries, starting from 0.
  test "no entries sync" do
    assert_equal 0, @account.balances.count

    expected = [ 0, 0 ]
    calculated = Balance::ForwardCalculator.new(@account).calculate

    assert_equal expected, calculated.map(&:balance)
  end

  test "valuations sync" do
    create_valuation(account: @account, date: 4.days.ago.to_date, amount: 17000)
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 19000)

    expected = [ 0, 17000, 17000, 19000, 19000, 19000 ]
    calculated = Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "transactions sync" do
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500) # income
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: 100) # expense

    expected = [ 0, 500, 500, 400, 400, 400 ]
    calculated = Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "multi-entry sync" do
    create_transaction(account: @account, date: 8.days.ago.to_date, amount: -5000)
    create_valuation(account: @account, date: 6.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 6.days.ago.to_date, amount: -500)
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500)
    create_valuation(account: @account, date: 3.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: 100)

    expected = [ 0, 5000, 5000, 17000, 17000, 17500, 17000, 17000, 16900, 16900 ]
    calculated = Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "multi-currency sync" do
    ExchangeRate.create! date: 1.day.ago.to_date, from_currency: "EUR", to_currency: "USD", rate: 1.2

    create_transaction(account: @account, date: 3.days.ago.to_date, amount: -100, currency: "USD")
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -300, currency: "USD")

    # Transaction in different currency than the account's main currency
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: -500, currency: "EUR") # €500 * 1.2 = $600

    expected = [ 0, 100, 400, 1000, 1000 ]
    calculated = Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "holdings and trades sync" do
    aapl = securities(:aapl)

    # Account starts at a value of $5000
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 5000)

    # Share purchase reduces cash balance by $1000, but keeps overall balance same
    create_trade(aapl, account: @account, qty: 10, date: 1.day.ago.to_date, price: 100)

    Holding.create!(date: 1.day.ago.to_date, account: @account, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")
    Holding.create!(date: Date.current, account: @account, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")

    # Given constant prices, overall balance (account value) should be constant
    # (the single trade doesn't affect balance; it just alters cash vs. holdings composition)
    expected = [ 0, 5000, 5000, 5000 ]
    calculated = Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  # Balance calculator is entirely reliant on HoldingCalculator and respects whatever holding records it creates.
  test "holdings are additive to total balance" do
    aapl = securities(:aapl)

    # Account starts at a value of $5000
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 5000)

    # Even though there are no trades in the history, the calculator will still add the holdings to the total balance
    Holding.create!(date: 1.day.ago.to_date, account: @account, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")
    Holding.create!(date: Date.current, account: @account, security: aapl, qty: 10, price: 100, amount: 1000, currency: "USD")

    # Start at zero, then valuation of $5000, then tack on $1000 of holdings for remaining 2 days
    expected = [ 0, 5000, 6000, 6000 ]
    calculated = Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end
end
