require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:depository)
  end

  test "gets accounts list" do
    get accounts_url
    assert_response :success

    @user.family.accounts.manual.each do |account|
      assert_dom "#" + dom_id(account), count: 1
    end

    @user.family.plaid_items.each do |item|
      assert_dom "#" + dom_id(item), count: 1
    end
  end

  test "new" do
    get new_account_path
    assert_response :ok
  end

  test "can sync an account" do
    post sync_account_path(@account)
    assert_redirected_to account_path(@account)
  end

  test "can sync all accounts" do
    post sync_all_accounts_path
    assert_redirected_to accounts_path
  end
end
