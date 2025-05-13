require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:depository)
  end

  test "new" do
    get new_account_path
    assert_response :ok
  end

  test "can sync an account" do
    post sync_account_path(@account)
    assert_redirected_to account_path(@account)
  end
end
