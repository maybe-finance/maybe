require "test_helper"

class AccountTest < ActiveSupport::TestCase

  test "new account should be valid" do
    depository = Account::Depository.create!
    account = Account.create!(family: families(:dylan_family), name: "Explicit Checking", balance: 1200, accountable: depository)
    assert account.valid?
    assert_not_nil account.accountable_id
    assert_not_nil account.accountable
  end

end