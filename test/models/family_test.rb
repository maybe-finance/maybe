require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  def setup
    @dylan_family = families(:dylan_family)
  end

  test "should have many users" do
    assert @dylan_family.users.size > 0
    assert @dylan_family.users.include?(users(:family_admin))
  end

  test "should have many accounts" do
    assert @dylan_family.accounts.size > 0
  end

  test "should destroy dependent users" do
    assert_difference("User.count", -@dylan_family.users.count) do
      @dylan_family.destroy
    end
  end

  test "should destroy dependent accounts" do
    assert_difference("Account.count", -@dylan_family.accounts.count) do
      @dylan_family.destroy
    end
  end
end
