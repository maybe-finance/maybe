require "test_helper"

class Account::ReverseBalanceCalculatorTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @account = families(:empty).accounts.create!(
      name: "Test",
      balance: 20000,
      currency: "USD",
      accountable: Investment.new
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

    expected = [ 17000, 19000,19000, 20000, 20000 ]
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

  private 
    def chronological_balances_for(account)
      series = Account::ReverseBalanceCalculator.new(account).calculate

      series.sort_by(&:date).map(&:balance)
    end
end
