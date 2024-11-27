require "test_helper"

class Account::HoldingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
    @account = accounts(:investment)
    @holding = @account.holdings.current.first
  end

  test "gets holdings" do
    get account_holdings_url(account_id: @account.id)
    assert_response :success
  end

  test "gets holding" do
    get account_holding_path(@holding)

    assert_response :success
  end

  test "destroys holding and associated entries" do
    assert_difference -> { Account::Holding.count } => -1,
                      -> { Account::Entry.count } => -1 do
      delete account_holding_path(@holding)
    end

    assert_redirected_to account_path(@holding.account)
    assert_empty @holding.account.entries.where(entryable: @holding.account.trades.where(security: @holding.security))
  end
end
