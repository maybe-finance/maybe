require "test_helper"

class AccountGroupTest < ActiveSupport::TestCase
  def setup
    @account_group = Account::Group.new(
      type: Account::Depository,
      total_value: 300_00,
      percentage_held: 50.0
    )
  end

  test "param name is set correctly" do
    assert_equal "account-depository", @account_group.param
  end
end
