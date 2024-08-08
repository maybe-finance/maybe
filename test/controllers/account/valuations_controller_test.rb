require "test_helper"

class Account::ValuationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @entry = account_entries :valuation
  end

  test "should get index" do
    get account_valuations_url(@entry.account)
    assert_response :success
  end

  test "should get new" do
    get new_account_valuation_url(@entry.account)
    assert_response :success
  end
end
