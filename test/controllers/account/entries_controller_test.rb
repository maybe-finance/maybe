require "test_helper"

class Account::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_entries :transaction
    @valuation = account_entries :valuation
  end

  test "should edit valuation entry" do
    get edit_account_entry_url(@valuation.account, @valuation)
    assert_response :success
  end

  test "should show transaction entry" do
    get account_entry_url(@transaction.account, @transaction)
    assert_response :success
  end

  test "should show valuation entry" do
    get account_entry_url(@valuation.account, @valuation)
    assert_response :success
  end

  test "should get list of transaction entries" do
    get transaction_account_entries_url(@transaction.account)
    assert_response :success
  end

  test "should get list of valuation entries" do
    get valuation_account_entries_url(@valuation.account)
    assert_response :success
  end

  test "gets new entry by type" do
    get new_account_entry_url(@valuation.account, entryable_type: "Account::Valuation")
    assert_response :success
  end

  test "should create valuation" do
    assert_difference [ "Account::Entry.count", "Account::Valuation.count" ], 1 do
      post account_entries_url(@valuation.account), params: {
        account_entry: {
          name: "Manual valuation",
          amount: 19800,
          date: Date.current,
          currency: @valuation.account.currency,
          entryable_type: "Account::Valuation",
          entryable_attributes: {}
        }
      }
    end

    assert_equal "Valuation created", flash[:notice]
    assert_enqueued_with job: AccountSyncJob
    assert_redirected_to account_path(@valuation.account)
  end

  test "error when valuation already exists for date" do
    assert_no_difference_in_entries do
      post account_entries_url(@valuation.account), params: {
        account_entry: {
          amount: 19800,
          date: @valuation.date,
          currency: @valuation.currency,
          entryable_type: "Account::Valuation",
          entryable_attributes: {}
        }
      }
    end

    assert_equal "Date has already been taken", flash[:error]
    assert_redirected_to account_path(@valuation.account)
  end

  test "can update entry without entryable attributes" do
    assert_no_difference_in_entries do
      patch account_entry_url(@valuation.account, @valuation), params: {
        account_entry: {
          name: "Updated name"
        }
      }
    end

    assert_redirected_to account_entry_url(@valuation.account, @valuation)
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "should update transaction entry with entryable attributes" do
    assert_no_difference_in_entries do
      patch account_entry_url(@transaction.account, @transaction), params: {
        account_entry: {
          name: "Updated name",
          date: Date.current,
          currency: "USD",
          amount: 20,
          entryable_type: @transaction.entryable_type,
          entryable_attributes: {
            id: @transaction.entryable_id,
            tag_ids: [ Tag.first.id, Tag.second.id ],
            category_id: Category.first.id,
            merchant_id: Merchant.first.id,
            notes: "test notes",
            excluded: false
          }
        }
      }
    end

    assert_redirected_to account_entry_url(@transaction.account, @transaction)
    assert_enqueued_with(job: AccountSyncJob)
  end

  test "should destroy transaction entry" do
    [ @transaction, @valuation ].each do |entry|
      assert_difference -> { Account::Entry.count } => -1, -> { entry.entryable_class.count } => -1 do
        delete account_entry_url(entry.account, entry)
      end

      assert_redirected_to account_url(entry.account)
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
