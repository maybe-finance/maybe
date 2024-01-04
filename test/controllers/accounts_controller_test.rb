require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get accounts_index_url
    assert_response :success
  end

  test "should get assets" do
    get accounts_assets_url
    assert_response :success
  end

  test "should get cash" do
    get accounts_cash_url
    assert_response :success
  end

  test "should get investments" do
    get accounts_investments_url
    assert_response :success
  end

  test "should get show" do
    get accounts_show_url
    assert_response :success
  end

  test "should get credit" do
    get accounts_credit_url
    assert_response :success
  end

  test "should get debts" do
    get accounts_debts_url
    assert_response :success
  end
end
