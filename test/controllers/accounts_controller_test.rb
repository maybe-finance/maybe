require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:checking)
  end

  test "gets accounts list" do
    get accounts_url
    assert_response :success

    @user.family.accounts.each do |account|
      assert_dom "#" + dom_id(account), count: 1
    end
  end

  test "new" do
    get new_account_path
    assert_response :ok
  end

  test "show" do
    get account_path(@account)
    assert_response :ok
  end

  test "should update account" do
    patch account_url(@account), params: {
      account: {
        is_active: "0"
      }
    }

    assert_redirected_to account_url(@account)
    assert_equal "Account updated", flash[:notice]
  end

  test "should create account" do
    assert_difference -> { Account.count }, +1 do
      post accounts_path, params: { account: { accountable_type: "Account::Credit" } }
      assert_redirected_to account_url(Account.order(:created_at).last)
    end
  end

  test "should create a valuation together with account" do
    balance = 700
    start_date = 3.days.ago.to_date
    post accounts_path, params: { account: { accountable_type: "Account::Credit", balance:, start_date: } }

    new_valuation = Valuation.order(:created_at).last
    assert new_valuation.value == balance
    assert new_valuation.date == start_date
  end
end
