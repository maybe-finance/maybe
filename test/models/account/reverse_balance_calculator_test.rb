require "test_helper"

class Account::ReverseBalanceCalculatorTest < ActiveSupport::TestCase
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

  test "no entries sync" do
    assert_equal 0, @account.balances.count

    expected = [ @account.balance ]
    calculated = Account::ReverseBalanceCalculator.new(@account).calculate

    assert_equal expected, calculated.map(&:balance)
  end

  test "valuations sync" do 
    create_valuation(account: @account, date: 4.days.ago.to_date, amount: 17000)
    create_valuation(account: @account, date: 2.days.ago.to_date, amount: 19000) 

    expected = [ 17000, 17000, 19000, 19000, 20000, 20000 ]
    calculated = chronological_balances_for(@account)

    assert_equal expected, calculated
  end

  test "transactions sync" do 
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: 100)
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -500)

    expected = [ 19600, 19500, 19500, 20000, 20000, 20000 ]
    calculated = chronological_balances_for(@account)

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
    calculated = chronological_balances_for(@account)

    assert_equal expected, calculated
  end

  test "investment balance sync" do 
    @account.investment.update!(cash_balance: 18000, holdings_balance: 2000)
    
    # Transactions represent deposits / withdrawals from the brokerage account
    create_transaction(account: @account, date: 4.days.ago.to_date, amount: 100)
    create_transaction(account: @account, date: 2.days.ago.to_date, amount: -500) 

    # Trades either consume cash (buy) or generate cash (sell).  They do NOT change total balance, but do affect composition of cash/holdings.
    create_trade(securities(:msft), account: @account, date: 4.days.ago.to_date, qty: 1, price: 100)

    create_holding(date: Date.current, security: securities(:msft), amount: 2000)
    create_holding(date: 1.day.ago.to_date, security: securities(:msft), amount: 1900)
    create_holding(date: 2.days.ago.to_date, security: securities(:msft), amount: 1800)
    create_holding(date: 3.days.ago.to_date, security: securities(:msft), amount: 1700)
    create_holding(date: 4.days.ago.to_date, security: securities(:msft), amount: 1600)
    create_holding(date: 5.days.ago.to_date, security: securities(:msft), amount: 1500)

    expected = [ 19200, 19100, 19200, 19800, 19900, 20000 ]
    calculated = chronological_balances_for(@account)

    assert_equal expected, calculated
  end

  private 
    def chronological_balances_for(account)
      series = Account::ReverseBalanceCalculator.new(account).calculate

      series.sort_by(&:date).map(&:balance)
    end

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
