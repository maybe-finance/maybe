require "test_helper"

class Account::ReverseBalanceCalculatorTest < ActiveSupport::TestCase
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

  # When syncing backwards, we start with the account balance and generate everything from there.
  test "reverse no entries sync" do
    assert_equal 0, @account.balances.count

    expected = [ @account.balance ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate(reverse: true)

    assert_equal expected, calculated.map(&:balance)
  end

  # When syncing forwards, we don't care about the account balance.  We generate everything based on entries, starting from 0.
  test "forward no entries sync" do 
    assert_equal 0, @account.balances.count

    expected = [ 0 ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate

    assert_equal expected, calculated.map(&:balance)
  end

  test "forward valuations sync" do 
    create_valuation(account: @account, date: 4.days.ago.to_date, amount: 17000)
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 19000) 

    expected = [ 0, 17000, 17000, 19000, 19000, 19000 ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated 
  end

  test "reverse valuations sync" do 
    create_valuation(account: @account, date: 4.days.ago.to_date, amount: 17000)
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 19000) 

    expected = [ 17000, 17000, 19000, 19000, 20000, 20000 ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate(reverse: true).sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "forward transactions sync" do 
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500) # income
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: 100) # expense

    expected = [ 0, 500, 500, 400, 400, 400 ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "reverse transactions sync" do 
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500) # income
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: 100) # expense

    expected = [ 19600, 20100, 20100, 20000, 20000, 20000 ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate(reverse: true).sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "reverse multi-entry sync" do 
    create_transaction(account: @account, date: 8.days.ago.to_date, amount: -5000)
    create_valuation(account: @account, date: 6.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 6.days.ago.to_date, amount: -500)
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500)
    create_valuation(account: @account, date: 3.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: 100)

    expected = [ 12000, 17000, 17000, 17000, 16500, 17000, 17000, 20100, 20000, 20000 ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate(reverse: true) .sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "forward multi-entry sync" do 
    create_transaction(account: @account, date: 8.days.ago.to_date, amount: -5000)
    create_valuation(account: @account, date: 6.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 6.days.ago.to_date, amount: -500)
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: -500)
    create_valuation(account: @account, date: 3.days.ago.to_date, amount: 17000)
    create_transaction(account: @account, date: 1.day.ago.to_date, amount: 100)

    expected = [ 0, 5000, 5000, 17000, 17000, 17500, 17000, 17000, 16900, 16900 ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal expected, calculated
  end

  test "investment balance sync" do 
    @account.update!(cash_balance: 18000)
    
    # Transactions represent deposits / withdrawals from the brokerage account
    # Ex: We deposit $20,000 into the brokerage account
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -20000) 

    # Trades either consume cash (buy) or generate cash (sell).  They do NOT change total balance, but do affect composition of cash/holdings.
    # Ex: We buy 20 shares of MSFT at $100 for a total of $2000
    create_trade(securities(:msft), account: @account, date: 1.day.ago.to_date, qty: 20, price: 100)

    create_holding(date: Date.current, security: securities(:msft), amount: 2000)
    create_holding(date: 1.day.ago.to_date, security: securities(:msft), amount: 2000)
    create_holding(date: 2.days.ago.to_date, security: securities(:msft), amount: 0)

    expected = [ 0, 20000, 20000, 20000 ]
    calculated_backwards = Account::ReverseBalanceCalculator.new(@account).calculate(reverse: true).sort_by(&:date).map(&:balance)
    calculated_forwards = Account::ReverseBalanceCalculator.new(@account).calculate.sort_by(&:date).map(&:balance)

    assert_equal calculated_forwards, calculated_backwards
    assert_equal expected, calculated_forwards
  end

  private 
    def create_holding(date:, security:, amount:)
      Account::Holding.create!(
        account: @account,
        security: security,
        date: date,
        qty: 0, # not used
        price: 0, # not used
        amount: amount,
        currency: @account.currency 
      )
    end
end
