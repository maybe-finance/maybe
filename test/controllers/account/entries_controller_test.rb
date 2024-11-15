require "test_helper"

class Account::EntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in @user = users(:family_admin)
    @transaction = account_entries :transaction
    @valuation = account_entries :valuation
    @trade = account_entries :trade
  end

  # =================
  # Shared
  # =================

  test "should destroy entry" do
    [ @transaction, @valuation, @trade ].each do |entry|
      assert_difference -> { Account::Entry.count } => -1, -> { entry.entryable_class.count } => -1 do
        delete account_entry_url(entry.account, entry)
      end

      assert_redirected_to account_url(entry.account)
      assert_enqueued_with(job: SyncJob)
    end
  end

  test "gets show" do
    [ @transaction, @valuation, @trade ].each do |entry|
      get account_entry_url(entry.account, entry)
      assert_response :success
    end
  end

  test "gets edit" do
    [ @valuation ].each do |entry|
      get edit_account_entry_url(entry.account, entry)
      assert_response :success
    end
  end

  test "can update generic entry" do
    [ @transaction, @valuation, @trade ].each do |entry|
      assert_no_difference_in_entries do
        patch account_entry_url(entry.account, entry), params: {
          account_entry: {
            name: "Name",
            date: Date.current,
            currency: "USD",
            amount: 100
          }
        }
      end

      assert_redirected_to account_entry_url(entry.account, entry)
      assert_enqueued_with(job: SyncJob)
    end
  end

  private

    # Simple guard to verify that nested attributes are passed the record ID to avoid new creation of record
    # See `update_only` option of accepts_nested_attributes_for
    def assert_no_difference_in_entries(&block)
      assert_no_difference [ "Account::Entry.count", "Account::Transaction.count", "Account::Valuation.count" ], &block
    end
end
