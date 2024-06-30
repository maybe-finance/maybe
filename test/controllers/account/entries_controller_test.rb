require "test_helper"

class Account::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @account = accounts(:savings)
    @transaction_entry = @account.entries.account_transactions.first
    @valuation_entry = @account.entries.account_valuations.first
  end

  test "should edit valuation entry" do
    get edit_account_entry_url(@account, @valuation_entry)
    assert_response :success
  end

  test "should show transaction entry" do
    get account_entry_url(@account, @transaction_entry)
    assert_response :success
  end

  test "should show valuation entry" do
    get account_entry_url(@account, @valuation_entry)
    assert_response :success
  end

  test "should get list of transaction entries" do
    get transaction_account_entries_url(@account)
    assert_response :success
  end

  test "should get list of valuation entries" do
    get valuation_account_entries_url(@account)
    assert_response :success
  end

  test "can update entry without entryable attributes" do
    assert_no_difference_in_entries do
      patch account_entry_url(@account, @valuation_entry), params: {
        account_entry: {
          name: "Updated name"
        }
      }
    end

    assert_redirected_to account_entry_url(@account, @valuation_entry)
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "should update transaction entry with entryable attributes" do
    assert_no_difference_in_entries do
      patch account_entry_url(@account, @transaction_entry), params: {
        account_entry: {
          name: "Updated name",
          date: Date.current,
          currency: "USD",
          amount: 20,
          entryable_type: @transaction_entry.entryable_type,
          entryable_attributes: {
            id: @transaction_entry.entryable_id,
            tag_ids: [ Tag.first.id, Tag.second.id ],
            category_id: Category.first.id,
            merchant_id: Merchant.first.id,
            notes: "test notes",
            excluded: false
          }
        }
      }
    end

    assert_redirected_to account_entry_url(@account, @transaction_entry)
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "should destroy transaction entry" do
    [ @transaction_entry, @valuation_entry ].each do |entry|
      assert_difference -> { Account::Entry.count } => -1, -> { entry.entryable_class.count } => -1 do
        delete account_entry_url(@account, entry)
      end

      assert_redirected_to account_url(@account)
      assert_enqueued_with(job: AccountSyncJob)
    end
  end

  private

    # Simple guard to verify that nested attributes are passed the record ID to avoid new creation of record
    # See `update_only` option of accepts_nested_attributes_for
    def assert_no_difference_in_entries(&block)
      assert_no_difference [ "Account::Entry.count", "Account::Transaction.count", "Account::Valuation.count" ], &block
    end
end
