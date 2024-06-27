require "test_helper"

class Account::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction_entry = account_entries(:checking_one)
  end

  test "should get edit" do
    get edit_account_entry_url(@transaction_entry.account, @transaction_entry)
    assert_response :success
  end

  test "should get show" do
    get account_entry_url(@transaction_entry.account, @transaction_entry)
    assert_response :success
  end

  test "should get list of transaction entries" do
    get transaction_account_entries_url(Account.first)
    assert_response :success
  end

  test "should update transaction entry" do
    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], 0 do
      patch account_entry_url(@transaction_entry.account, @transaction_entry), params: {
        account_entry: {
          amount: @transaction_entry.amount,
          currency: @transaction_entry.currency,
          date: @transaction_entry.date,
          name: @transaction_entry.name,
          entryable_type: "Account::Transaction",
          entryable_attributes: {
            id: @transaction_entry.account_transaction.id,
            tag_ids: [ Tag.first.id, Tag.second.id ],
            category_id: Category.first.id,
            merchant_id: Merchant.first.id,
            notes: "some note",
            excluded: false
          }
        }
      }
    end

    assert_redirected_to account_entry_url(@transaction_entry.account, @transaction_entry)
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "should destroy transaction entry" do
    assert_difference [ "Account::Entry.count", "Account::Transaction.count" ], -1 do
      delete account_entry_url(@transaction_entry.account, @transaction_entry)
    end

    assert_redirected_to account_url(@transaction_entry.account)
    assert_enqueued_with(job: AccountSyncJob)
  end
end
