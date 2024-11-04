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

  test "create" do
    assert_difference [ "Account::Entry.count", "Account::Valuation.count" ], 1 do
      post account_valuations_url(@entry.account), params: {
        account_entry: {
          name: "Manual valuation",
          amount: 19800,
          date: Date.current,
          currency: "USD"
        }
      }
    end

    assert_equal "Valuation created successfully.", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_valuations_path(@entry.account)
  end

  test "error when valuation already exists for date" do
    assert_no_difference [ "Account::Entry.count", "Account::Valuation.count" ] do
      post account_valuations_url(@entry.account), params: {
        account_entry: {
          amount: 19800,
          date: @entry.date,
          currency: "USD"
        }
      }
    end

    assert_equal "Date has already been taken", flash[:alert]
    assert_redirected_to @entry.account
  end
end
