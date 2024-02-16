require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    depository = Account::Depository.create!
    @account = Account.create!(family: families(:dylan_family), name: "Explicit Checking", original_balance: 1200, accountable: depository)
  end

  test "new account should be valid" do
    assert @account.valid?
    assert_not_nil @account.accountable_id
    assert_not_nil @account.accountable
  end
end
