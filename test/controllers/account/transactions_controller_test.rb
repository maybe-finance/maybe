require "test_helper"

class Account::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @entry = account_entries :transaction
  end

  test "should get index" do
    get account_transactions_url(@entry.account)
    assert_response :success
  end

  test "should get show" do
    get account_transaction_url(@entry.account, @entry)
    assert_response :success
  end
end
