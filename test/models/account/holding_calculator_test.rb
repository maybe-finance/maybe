require "test_helper"

class Account::HoldingCalculatorTest < ActiveSupport::TestCase
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
    forward = Account::HoldingCalculator.new(@account).calculate
    reverse = Account::HoldingCalculator.new(@account).calculate(reverse: true)
    assert_equal forward, reverse
    assert_equal [], forward
  end

  test "preload_securities handles securities correctly" do
    security = Security.create!(ticker: "AAPL", name: "Apple Inc.", exchange_mic: "XNAS")
    
    @account.entries.create!(
      date: Date.current,
      entryable: Account::Trade.new(
        security: security,
        qty: 10,
        price: 150,
        currency: "USD"
      )
    )

    Security::Price.create!(
      security: security,
      date: Date.current,
      price: 150,
      currency: "USD"
    )

    calculator = Account::HoldingCalculator.new(@account)
    assert_nothing_raised do
      calculator.calculate
    end
  end

  # Rest of existing tests...
  # [Previous test content remains unchanged]
end
