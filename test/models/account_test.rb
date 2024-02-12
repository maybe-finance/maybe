require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    depository = Account::Depository.create!
    @account = Account.create!(family: families(:dylan_family), name: "Explicit Checking", balance_cents: 1200, accountable: depository)
  end

  test "new account should be valid" do
    assert @account.valid?
    assert_not_nil @account.accountable_id
    assert_not_nil @account.accountable
  end

  test "balance returns Money object" do
    @account.balance = 10
    assert_instance_of Money, @account.balance
    assert_equal :usd, @account.balance.currency.id
  end

  test "correctly assigns Money objects to the attribute" do
    @account.balance = Money.new(2500, "USD")
    assert_equal 2500, @account.balance_cents
  end

  test "balance_cents can be updated" do
    new_balance = Money.new(10000, "USD")
    @account.balance = new_balance
    assert_equal new_balance, @account.balance
  end

  test ".by_type" do
    account = families(:dylan_family).accounts

    assert_equal 1, account.by_type.count
    assert_instance_of Account::Group, account.by_type.first
  end
end
