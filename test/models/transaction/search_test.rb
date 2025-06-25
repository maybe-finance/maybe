require "test_helper"

class Transaction::SearchTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:dylan_family)
    @checking_account = accounts(:depository)
    @credit_card_account = accounts(:credit_card)
    @loan_account = accounts(:loan)

    # Clean up existing entries/transactions from fixtures to ensure test isolation
    @family.accounts.each { |account| account.entries.delete_all }
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
      kind: "funds_movement"
    )

    payment_entry = create_transaction(
      account: @credit_card_account,
      amount: -300,
      kind: "cc_payment"
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
    transfer_results = Transaction::Search.new(@family, filters: { types: [ "transfer" ] }).transactions_scope
    transfer_ids = transfer_results.pluck(:id)

    assert_includes transfer_ids, transfer_entry.entryable.id
    assert_includes transfer_ids, payment_entry.entryable.id
    assert_includes transfer_ids, loan_payment_entry.entryable.id
    assert_not_includes transfer_ids, one_time_entry.entryable.id
    assert_not_includes transfer_ids, standard_entry.entryable.id

    # Test expense type filter (excludes transfer kinds but includes one_time)
    expense_results = Transaction::Search.new(@family, filters: { types: [ "expense" ] }).transactions_scope
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

    income_results = Transaction::Search.new(@family, filters: { types: [ "income" ] }).transactions_scope
    income_ids = income_results.pluck(:id)

    assert_includes income_ids, income_entry.entryable.id
    assert_not_includes income_ids, standard_entry.entryable.id
    assert_not_includes income_ids, loan_payment_entry.entryable.id
    assert_not_includes income_ids, transfer_entry.entryable.id

    # Test combined expense and income filter (excludes transfer kinds but includes one_time)
    non_transfer_results = Transaction::Search.new(@family, filters: { types: [ "expense", "income" ] }).transactions_scope
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
      kind: "funds_movement"
    )

    uncategorized_loan_payment = create_transaction(
      account: @loan_account,
      amount: 300,
      kind: "loan_payment"
    )

    # Search for uncategorized transactions
    uncategorized_results = Transaction::Search.new(@family, filters: { categories: [ "Uncategorized" ] }).transactions_scope
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
      kind: "funds_movement"
    )

    # Test new family-based API
    search = Transaction::Search.new(@family, filters: { types: [ "expense" ] })
    results = search.transactions_scope
    result_ids = results.pluck(:id)

    # Should include expense transactions
    assert_includes result_ids, transaction1.entryable.id
    # Should exclude transfer transactions
    assert_not_includes result_ids, transaction2.entryable.id

    # Test that the relation builds from family.transactions correctly
    assert_equal @family.transactions.joins(entry: :account).where(
      "entries.amount >= 0 AND NOT (transactions.kind IN ('funds_movement', 'cc_payment', 'loan_payment'))"
    ).count, results.count
  end

  test "family-based API requires family parameter" do
    assert_raises(NoMethodError) do
      search = Transaction::Search.new({ types: [ "expense" ] })
      search.transactions_scope  # This will fail when trying to call .transactions on a Hash
    end
  end

  # Totals method tests (lifted from Transaction::TotalsTest)

  test "totals computes basic expense and income totals" do
    # Create expense transaction
    expense_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      category: categories(:food_and_drink),
      kind: "standard"
    )

    # Create income transaction
    income_entry = create_transaction(
      account: @checking_account,
      amount: -200,
      kind: "standard"
    )

    search = Transaction::Search.new(@family)
    totals = search.totals

    assert_equal 2, totals.count
    assert_equal Money.new(100, "USD"), totals.expense_money # $100
    assert_equal Money.new(200, "USD"), totals.income_money  # $200
  end

  test "totals handles multi-currency transactions with exchange rates" do
    # Create EUR transaction
    eur_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      currency: "EUR",
      kind: "standard"
    )

    # Create exchange rate EUR -> USD
    ExchangeRate.create!(
      from_currency: "EUR",
      to_currency: "USD",
      rate: 1.1,
      date: eur_entry.date
    )

    # Create USD transaction
    usd_entry = create_transaction(
      account: @checking_account,
      amount: 50,
      currency: "USD",
      kind: "standard"
    )

    search = Transaction::Search.new(@family)
    totals = search.totals

    assert_equal 2, totals.count
    # EUR 100 * 1.1 + USD 50 = 110 + 50 = 160
    assert_equal Money.new(160, "USD"), totals.expense_money
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "totals handles missing exchange rates gracefully" do
    # Create EUR transaction without exchange rate
    eur_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      currency: "EUR",
      kind: "standard"
    )

    search = Transaction::Search.new(@family)
    totals = search.totals

    assert_equal 1, totals.count
    # Should use rate of 1 when exchange rate is missing
    assert_equal Money.new(100, "USD"), totals.expense_money # EUR 100 * 1
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "totals respects category filters" do
    # Create transactions in different categories
    food_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      category: categories(:food_and_drink),
      kind: "standard"
    )

    other_entry = create_transaction(
      account: @checking_account,
      amount: 50,
      category: categories(:income),
      kind: "standard"
    )

    # Filter by food category only
    search = Transaction::Search.new(@family, filters: { categories: [ "Food & Drink" ] })
    totals = search.totals

    assert_equal 1, totals.count
    assert_equal Money.new(100, "USD"), totals.expense_money # Only food transaction
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "totals respects type filters" do
    # Create expense and income transactions
    expense_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      kind: "standard"
    )

    income_entry = create_transaction(
      account: @checking_account,
      amount: -200,
      kind: "standard"
    )

    # Filter by expense type only
    search = Transaction::Search.new(@family, filters: { types: [ "expense" ] })
    totals = search.totals

    assert_equal 1, totals.count
    assert_equal Money.new(100, "USD"), totals.expense_money
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "totals handles empty results" do
    search = Transaction::Search.new(@family)
    totals = search.totals

    assert_equal 0, totals.count
    assert_equal Money.new(0, "USD"), totals.expense_money
    assert_equal Money.new(0, "USD"), totals.income_money
  end
end
