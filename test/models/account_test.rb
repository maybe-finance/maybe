require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    depository = account_depositories(:checking)
    @account = accounts(:checking)
    @account.accountable = depository
  end

  test "new account should be valid" do
    assert @account.valid?
    assert_not_nil @account.accountable_id
    assert_not_nil @account.accountable
  end
end
