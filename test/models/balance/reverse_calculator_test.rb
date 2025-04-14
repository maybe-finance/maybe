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
end
