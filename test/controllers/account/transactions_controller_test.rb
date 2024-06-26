require "test_helper"

class Account::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_transactions(:checking_one)
    @account = @transaction.entry.account
    @recent_transactions = @user.family.transactions.ordered_with_entry.limit(20).to_a
  end

  test "should show transaction" do
    get account_transaction_url(@transaction.entry.account, @transaction)
    assert_response :success
  end

  test "should update transaction" do
    patch account_transaction_url(@transaction.entry.account, @transaction), params: {
      account_entry: {
        amount: @transaction.entry.amount,
        currency: @transaction.entry.currency,
        date: @transaction.entry.date,
        name: @transaction.entry.name,
        tag_ids: [ Tag.first.id, Tag.second.id ]
      }
    }

    assert_redirected_to account_transaction_url(@transaction.entry.account, @transaction)
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "should destroy transaction" do
    assert_difference("Account::Transaction.count", -1) do
      delete account_transaction_url(@transaction.entry.account, @transaction)
    end

    assert_redirected_to account_url(@transaction.entry.account)
    assert_enqueued_with(job: AccountSyncJob)
  end
end
