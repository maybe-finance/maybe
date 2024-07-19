require "test_helper"

class Account::HoldingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @account = accounts(:investment)
    @holding = @account.holdings.current.first
  end

  test "gets holdings" do
    get account_holdings_url(@account)
    assert_response :success
  end

  test "gets holding" do
    get account_holding_path(@account, @holding)

    assert_response :success
  end
end
