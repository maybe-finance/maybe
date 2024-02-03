require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:one)  # Assuming you have fixture data set up
    @account ||= Account.new(name: "Sample Account", balance: Money.new(0, "USD"))
  end

  test "balance_cents returns Money object" do
    @account.balance = 750
    assert_instance_of Money, @account.balance_cents
    assert_equal :usd, @account.balance_cents.currency.id
  end

  test "correctly assigns Money objects to the attribute" do
    @account.balance_cents = Money.new(2500, :usd)
    assert_equal 2500, @account.balance
  end
end
