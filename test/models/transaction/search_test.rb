require "test_helper"

class Transaction::SearchTest < ActiveSupport::TestCase
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
      category: categories(:food_and_drink),
      kind: "standard"
    )

    transfer_entry = create_transaction(
      account: @checking_account,
      amount: 200,
      kind: "transfer"
    )

    payment_entry = create_transaction(
      account: @credit_card_account,
      amount: -300,
      kind: "payment"
    )

    loan_payment_entry = create_transaction(
      account: @loan_account,
      amount: 400,
      kind: "loan_payment"
    )

    one_time_entry = create_transaction(
      account: @checking_account,
      amount: 500,
      kind: "one_time"
    )

    # Test transfer type filter (includes loan_payment)
    transfer_results = Transaction::Search.new(@family, filters: { types: [ "transfer" ] }).relation
    transfer_ids = transfer_results.pluck(:id)



    assert_includes transfer_ids, transfer_entry.entryable.id
    assert_includes transfer_ids, payment_entry.entryable.id
    assert_includes transfer_ids, loan_payment_entry.entryable.id
    assert_not_includes transfer_ids, one_time_entry.entryable.id
    assert_not_includes transfer_ids, standard_entry.entryable.id

    # Test expense type filter (excludes transfer kinds but includes one_time)
    expense_results = Transaction::Search.new(@family, filters: { types: [ "expense" ] }).relation
    expense_ids = expense_results.pluck(:id)

    assert_includes expense_ids, standard_entry.entryable.id
    assert_includes expense_ids, one_time_entry.entryable.id
    assert_not_includes expense_ids, loan_payment_entry.entryable.id
    assert_not_includes expense_ids, transfer_entry.entryable.id
    assert_not_includes expense_ids, payment_entry.entryable.id

    # Test income type filter
    income_entry = create_transaction(
      account: @checking_account,
      amount: -600,
      kind: "standard"
    )

    income_results = Transaction::Search.new(@family, filters: { types: [ "income" ] }).relation
    income_ids = income_results.pluck(:id)

    assert_includes income_ids, income_entry.entryable.id
    assert_not_includes income_ids, standard_entry.entryable.id
    assert_not_includes income_ids, loan_payment_entry.entryable.id
    assert_not_includes income_ids, transfer_entry.entryable.id

    # Test combined expense and income filter (excludes transfer kinds but includes one_time)
    non_transfer_results = Transaction::Search.new(@family, filters: { types: [ "expense", "income" ] }).relation
    non_transfer_ids = non_transfer_results.pluck(:id)

    assert_includes non_transfer_ids, standard_entry.entryable.id
    assert_includes non_transfer_ids, income_entry.entryable.id
    assert_includes non_transfer_ids, one_time_entry.entryable.id
    assert_not_includes non_transfer_ids, loan_payment_entry.entryable.id
    assert_not_includes non_transfer_ids, transfer_entry.entryable.id
    assert_not_includes non_transfer_ids, payment_entry.entryable.id
  end

  test "search category filter handles uncategorized transactions correctly with kind filtering" do
    # Create uncategorized transactions of different kinds
    uncategorized_standard = create_transaction(
      account: @checking_account,
      amount: 100,
      kind: "standard"
    )

    uncategorized_transfer = create_transaction(
      account: @checking_account,
      amount: 200,
      kind: "transfer"
    )

    uncategorized_loan_payment = create_transaction(
      account: @loan_account,
      amount: 300,
      kind: "loan_payment"
    )

    # Search for uncategorized transactions
    uncategorized_results = Transaction::Search.new(@family, filters: { categories: [ "Uncategorized" ] }).relation
    uncategorized_ids = uncategorized_results.pluck(:id)

    # Should include standard uncategorized transactions
    assert_includes uncategorized_ids, uncategorized_standard.entryable.id
    # Should include loan_payment since it's treated specially in category logic
    assert_includes uncategorized_ids, uncategorized_loan_payment.entryable.id

    # Should exclude transfer transactions even if uncategorized
    assert_not_includes uncategorized_ids, uncategorized_transfer.entryable.id
  end

  test "new family-based API works correctly" do
    # Create transactions for testing
    transaction1 = create_transaction(
      account: @checking_account,
      amount: 100,
      category: categories(:food_and_drink),
      kind: "standard"
    )

    transaction2 = create_transaction(
      account: @checking_account,
      amount: 200,
      kind: "transfer"
    )

    # Test new family-based API
    search = Transaction::Search.new(@family, filters: { types: [ "expense" ] })
    results = search.relation
    result_ids = results.pluck(:id)

    # Should include expense transactions
    assert_includes result_ids, transaction1.entryable.id
    # Should exclude transfer transactions
    assert_not_includes result_ids, transaction2.entryable.id

    # Test that the relation builds from family.transactions correctly
    assert_equal @family.transactions.joins(entry: :account).where(
      "entries.amount >= 0 AND NOT (transactions.kind IN ('transfer', 'payment', 'loan_payment'))"
    ).count, results.count
  end

  test "family-based API requires family parameter" do
    assert_raises(NoMethodError) do
      search = Transaction::Search.new({ types: [ "expense" ] })
      search.relation  # This will fail when trying to call .transactions on a Hash
    end
  end
end
