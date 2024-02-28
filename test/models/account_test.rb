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

  test "should calculate effective start date" do
    # Oldest transaction on this account is 30 days ago
    assert_equal 30.days.ago.to_date, @account.effective_start_date
  end
end
