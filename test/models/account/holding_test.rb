require "test_helper"

class Account::HoldingTest < ActiveSupport::TestCase
  setup do
    @holding = account_holdings(:one)
  end

  test "should create valid holding" do
    holding = Account::Holding.new(
      account: @holding.account,
      security: securities(:different_security),
      date: @holding.date,
      qty: 100,
      price: 50,
      amount: 5000,
      currency: "USD"
    )
    assert holding.valid?
    assert holding.save
  end

  test "should not create duplicate holding" do
    holding = Account::Holding.new(
      account: @holding.account,
      security: @holding.security,
      date: @holding.date,
      qty: 100,
      price: 50,
      amount: 5000,
      currency: @holding.currency
    )
    assert_not holding.valid?
    assert_includes holding.errors[:date], "holding already exists for this account, security, date, and currency"
  end
end
