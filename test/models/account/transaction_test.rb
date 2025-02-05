require "test_helper"

class Account::TransactionTest < ActiveSupport::TestCase
  include Account::EntriesTestHelper

  setup do
    @family = families(:dylan_family)
    @active_account = accounts(:depository)
    @inactive_account = accounts(:credit_card)
    @scheduled_for_deletion_account = accounts(:investment)

    @inactive_account.update!(is_active: false)
    @scheduled_for_deletion_account.update!(scheduled_for_deletion: true)
  end

  test "from_active_accounts scope only returns transactions from active accounts" do
    # Create transactions for all account types
    active_transaction = create_transaction(account: @active_account, name: "Active transaction")
    inactive_transaction = create_transaction(account: @inactive_account, name: "Inactive transaction")
    deletion_transaction = create_transaction(account: @scheduled_for_deletion_account, name: "Scheduled for deletion transaction")

    # Test the scope
    transactions = Account::Transaction.from_active_accounts

    # Should include transaction from active account
    assert_includes transactions, active_transaction.entryable

    # Should not include transaction from inactive account
    assert_not_includes transactions, inactive_transaction.entryable

    # Should not include transaction from account scheduled for deletion
    assert_not_includes transactions, deletion_transaction.entryable
  end
end
