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

  test "destroys holding and associated entries" do
    assert_difference -> { Account::Holding.count } => -1,
                      -> { Account::Entry.count } => -1 do
      delete account_holding_path(@account, @holding)
    end

    assert_redirected_to account_holdings_path(@account)
    assert_empty @account.entries.where(entryable: @account.trades.where(security: @holding.security))
  end
end
