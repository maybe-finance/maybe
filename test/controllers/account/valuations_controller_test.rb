require "test_helper"

class Account::ValuationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @valuation = account_valuations(:savings_one)
    @account = @valuation.account
  end

  test "get valuations for an account" do
    get account_valuations_url(@account)
    assert_response :success
  end

  test "new" do
    get new_account_valuation_url(@account)
    assert_response :success
  end

  test "should create valuation" do
    assert_difference("Account::Valuation.count") do
      post account_valuations_url(@account), params: {
        account_valuation: {
          value: 19800,
          date: Date.current
        }
      }
    end

    assert_equal "Valuation created", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@account)
  end

  test "error when valuation already exists for date" do
    assert_difference("Account::Valuation.count", 0) do
      post account_valuations_url(@account), params: {
        account_valuation: {
          value: 19800,
          date: @valuation.date
        }
      }
    end

    assert_equal "Date has already been taken", flash[:error]
    assert_redirected_to account_path(@account)
  end

  test "should update valuation" do
    patch account_valuation_url(@account, @valuation), params: {
      account_valuation: {
        value: 19550,
        date: Date.current
      }
    }

    assert_equal "Valuation updated", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@account)
  end

  test "should destroy valuation" do
    assert_difference("Account::Valuation.count", -1) do
      delete account_valuation_url(@account, @valuation)
    end

    assert_equal "Valuation deleted", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@account)
  end
end
