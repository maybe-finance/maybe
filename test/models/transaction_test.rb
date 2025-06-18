require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:dylan_family)
    @checking_account = accounts(:depository)
    @credit_card_account = accounts(:credit_card)
    @loan_account = accounts(:loan)
  end

  test "search filters by transaction types using kind enum" do
    # Create different types of transactions using the helper method
    standard_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      category: categories(:food_and_drink)
    )
    standard_entry.entryable.update!(kind: "standard")

    transfer_entry = create_transaction(
      account: @checking_account,
      amount: 200
    )
    transfer_entry.entryable.update!(kind: "transfer")

    payment_entry = create_transaction(
      account: @credit_card_account,
      amount: -300
    )
    payment_entry.entryable.update!(kind: "payment")

    loan_payment_entry = create_transaction(
      account: @loan_account,
      amount: 400
    )
    loan_payment_entry.entryable.update!(kind: "loan_payment")

    one_time_entry = create_transaction(
      account: @checking_account,
      amount: 500
    )
    one_time_entry.entryable.update!(kind: "one_time")

    # Test transfer type filter
    transfer_results = Transaction.search(types: [ "transfer" ])
    transfer_ids = transfer_results.pluck(:id)

    assert_includes transfer_ids, transfer_entry.entryable.id
    assert_includes transfer_ids, payment_entry.entryable.id
    assert_includes transfer_ids, one_time_entry.entryable.id
    assert_not_includes transfer_ids, standard_entry.entryable.id
    assert_not_includes transfer_ids, loan_payment_entry.entryable.id

    # Test expense type filter (should include loan_payment)
    expense_results = Transaction.search(types: [ "expense" ])
    expense_ids = expense_results.pluck(:id)

    assert_includes expense_ids, standard_entry.entryable.id
    assert_includes expense_ids, loan_payment_entry.entryable.id
    assert_not_includes expense_ids, transfer_entry.entryable.id
    assert_not_includes expense_ids, payment_entry.entryable.id
    assert_not_includes expense_ids, one_time_entry.entryable.id

    # Test income type filter
    income_entry = create_transaction(
      account: @checking_account,
      amount: -600
    )
    income_entry.entryable.update!(kind: "standard")

    income_results = Transaction.search(types: [ "income" ])
    income_ids = income_results.pluck(:id)

    assert_includes income_ids, income_entry.entryable.id
    assert_not_includes income_ids, standard_entry.entryable.id
    assert_not_includes income_ids, loan_payment_entry.entryable.id
    assert_not_includes income_ids, transfer_entry.entryable.id

    # Test combined expense and income filter (excludes transfers)
    non_transfer_results = Transaction.search(types: [ "expense", "income" ])
    non_transfer_ids = non_transfer_results.pluck(:id)

    assert_includes non_transfer_ids, standard_entry.entryable.id
    assert_includes non_transfer_ids, income_entry.entryable.id
    assert_includes non_transfer_ids, loan_payment_entry.entryable.id
    assert_not_includes non_transfer_ids, transfer_entry.entryable.id
    assert_not_includes non_transfer_ids, payment_entry.entryable.id
    assert_not_includes non_transfer_ids, one_time_entry.entryable.id
  end

  test "search category filter handles uncategorized transactions correctly with kind filtering" do
    # Create uncategorized transactions of different kinds
    uncategorized_standard = create_transaction(
      account: @checking_account,
      amount: 100
    )
    uncategorized_standard.entryable.update!(kind: "standard")

    uncategorized_transfer = create_transaction(
      account: @checking_account,
      amount: 200
    )
    uncategorized_transfer.entryable.update!(kind: "transfer")

    uncategorized_loan_payment = create_transaction(
      account: @loan_account,
      amount: 300
    )
    uncategorized_loan_payment.entryable.update!(kind: "loan_payment")

    # Search for uncategorized transactions
    uncategorized_results = Transaction.search(categories: [ "Uncategorized" ])
    uncategorized_ids = uncategorized_results.pluck(:id)

    # Should include standard and loan_payment (budget-relevant) uncategorized transactions
    assert_includes uncategorized_ids, uncategorized_standard.entryable.id
    assert_includes uncategorized_ids, uncategorized_loan_payment.entryable.id

    # Should exclude transfer transactions even if uncategorized
    assert_not_includes uncategorized_ids, uncategorized_transfer.entryable.id
  end
end
