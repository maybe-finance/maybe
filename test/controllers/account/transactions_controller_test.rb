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

  test "update" do
    assert_no_difference [ "Account::Entry.count", "Account::Transaction.count" ] do
      patch account_transaction_url(@entry.account, @entry), params: {
        account_entry: {
          name: "Name",
          date: Date.current,
          currency: "USD",
          amount: 100,
          nature: "income",
          entryable_type: @entry.entryable_type,
          entryable_attributes: {
            id: @entry.entryable_id,
            tag_ids: [ Tag.first.id, Tag.second.id ],
            category_id: Category.first.id,
            merchant_id: Merchant.first.id,
            notes: "test notes",
            excluded: false
          }
        }
      }
    end

    assert_equal "Transaction updated successfully.", flash[:notice]
    assert_redirected_to account_entry_url(@entry.account, @entry)
    assert_enqueued_with(job: AccountSyncJob)
  end
end
