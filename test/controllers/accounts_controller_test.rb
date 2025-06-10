require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:depository)
  end

  test "should get index" do
    get accounts_url
    assert_response :success
  end

  test "should sync account" do
    post sync_account_url(@account)
    assert_redirected_to account_url(@account)
  end

  test "should get chart" do
    get chart_account_url(@account)
    assert_response :success
  end

  test "should get sparkline" do
    get sparkline_account_url(@account)
    assert_response :success
  end
end
