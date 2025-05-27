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

  test "should handle sparkline errors gracefully" do
  # Mock an error in the balance_series method to bypass the rescue in sparkline_series
  Balance::ChartSeriesBuilder.any_instance.stubs(:balance_series).raises(StandardError.new("Test error"))

  get sparkline_account_url(@account)
  assert_response :success
  assert_match /Error/, response.body
end
end
