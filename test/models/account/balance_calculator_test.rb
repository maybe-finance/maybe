require "test_helper"

class Account::BalanceCalculatorTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    # Investment accounts are the only account types that (theoretically) can have valuations, transactions, and trades, so is a good "general purpose" account for testing
    @account = families(:empty).accounts.create!(name: "Test", balance: 20000, currency: "USD", accountable: Investment.new)
  end

  test "no entries sync" do
    assert_equal 0, @account.balances.count
    assert_equal [ @account.balance ], calculate(start_date: Date.current).map(&:balance)
  end

  test "valuations sync" do 
    create_valuation(account: @account, date: 4.days.ago.to_date, amount: 17000)
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 19000) 

    expected = [ 17000, 17000, 19000, 19000, 19000 ]
    calculated = calculate(start_date: 4.days.ago.to_date).map(&:balance)

    assert_equal expected, calculated
  end

  test "transactions sync" do 
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: 100)
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -500)

    expected = [ 19600, 19500, 19500, 20000, 20000, 20000 ]
    calculated = calculate(start_date: 5.days.ago.to_date).map(&:balance)

    assert_equal expected, calculated
  end

  test "reverse transactions sync" do 
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: 100)
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -500)

    expected = [ 19600, 19500, 19500, 20000, 20000, 20000 ]
    calculated = calculate(start_date: 5.days.ago.to_date).map(&:balance)

    assert_equal expected, calculated
  end

  test "trades sync" do
  end

  test "reverse trades sync" do
  end

  test "multi-entry sync" do
  end

  test "reverse multi-entry sync" do
  end

  private 
    def calculate(start_date: nil, is_partial_sync: false)
      Account::BalanceCalculator.new(@account, start_date).calculate(is_partial_sync:)
    end
end