require "test_helper"

class Account::TradesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @entry = account_entries :trade
  end

  test "should get index" do
    get account_trades_url(@entry.account)
    assert_response :success
  end

  test "should get new" do
    get new_account_trade_url(@entry.account)
    assert_response :success
  end
end
