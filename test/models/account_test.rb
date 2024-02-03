require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    Money.locale_backend = :i18n
    depository = Account::Depository.create!
    @account = Account.create!(family: families(:dylan_family), name: "Explicit Checking", balance: 1200, accountable: depository)
  end

  test "new account should be valid" do
    assert @account.valid?
    assert_not_nil @account.accountable_id
    assert_not_nil @account.accountable
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
