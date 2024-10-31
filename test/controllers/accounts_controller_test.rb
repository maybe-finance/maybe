require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:depository)
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

  test "edit" do
    get edit_account_path(@account)
    assert_response :ok
  end

  test "can sync an account" do
    post sync_account_path(@account)
    assert_response :no_content
  end

  test "can sync all accounts" do
    post sync_all_accounts_path
    assert_redirected_to accounts_url
    assert_equal "Successfully queued accounts for syncing.", flash[:notice]
  end

  test "should update account" do
    patch account_url(@account), params: {
      account: {
        name: "Updated name",
        is_active: "0",
        institution_id: institutions(:chase).id
      }
    }

    assert_redirected_to account_url(@account)
    assert_enqueued_with job: AccountSyncJob
    assert_equal "Account updated", flash[:notice]
  end

  test "updates account balance by creating new valuation" do
    assert_difference [ "Account::Entry.count", "Account::Valuation.count" ], 1 do
      patch account_url(@account), params: {
        account: {
          balance: 10000
        }
      }
    end

    assert_redirected_to account_url(@account)
    assert_enqueued_with job: AccountSyncJob
    assert_equal "Account updated", flash[:notice]
  end

  test "updates account balance by editing existing valuation for today" do
    @account.entries.create! date: Date.current, amount: 6000, currency: "USD", entryable: Account::Valuation.new

    assert_no_difference [ "Account::Entry.count", "Account::Valuation.count" ] do
      patch account_url(@account), params: {
        account: {
          balance: 10000
        }
      }
    end

    assert_redirected_to account_url(@account)
    assert_enqueued_with job: AccountSyncJob
    assert_equal "Account updated", flash[:notice]
  end
end
