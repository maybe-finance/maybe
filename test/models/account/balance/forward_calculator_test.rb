require "test_helper"

class Account::Balance::ForwardCalculatorTest < ActiveSupport::TestCase
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

  # When syncing forwards, we don't care about the account balance.  We generate everything based on entries, starting from 0.
  test "no entries sync" do
    assert_equal 0, @account.balances.count

    expected = [ 0, 0 ]
    calculated = Account::Balance::ForwardCalculator.new(@account).calculate

    assert_equal expected, calculated.map(&:balance)
  end

  test "valuations sync" do
    create_valuation(account: @account, date: 4.days.ago.to_date, amount: 17000)
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 19000)

    expected = [ 0, 17000, 17000, 19000, 19000, 19000 ]
    calculated = Account::Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "transactions sync" do
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500) # income
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: 100) # expense

    expected = [ 0, 500, 500, 400, 400, 400 ]
    calculated = Account::Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

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
    calculated = Account::Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "multi-currency sync" do
    ExchangeRate.create! date: 1.day.ago.to_date, from_currency: "EUR", to_currency: "USD", rate: 1.2

    create_transaction(account: @account, date: 3.days.ago.to_date, amount: -100, currency: "USD")
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -300, currency: "USD")

    # Transaction in different currency than the account's main currency
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: -500, currency: "EUR") # €500 * 1.2 = $600

    expected = [ 0, 100, 400, 1000, 1000 ]
    calculated = Account::Balance::ForwardCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end
end
