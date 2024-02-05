require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:bob)
    @account = accounts(:dylan_checking)
  end

  test "new" do
    get new_account_path
    assert_response :ok
  end

  test "show" do
    get account_path(@account)
    assert_response :ok
  end

  test "create" do
    assert_difference -> { Account.count }, +1 do
      post accounts_path, params: { account: { accountable_type: "Account::Credit" } }
      assert_redirected_to accounts_url
    end
  end
end
