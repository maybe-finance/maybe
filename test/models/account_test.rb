require "test_helper"

class AccountTest < ActiveSupport::TestCase
  def setup
    @account = accounts(:checking)
  end

  test "new account should be valid" do
    assert @account.valid?
    assert_not_nil @account.accountable_id
    assert_not_nil @account.accountable
  end
end
