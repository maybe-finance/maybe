require "test_helper"

class Transaction::TotalsTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:dylan_family)
    @checking_account = accounts(:depository)
    @credit_card_account = accounts(:credit_card)
    @loan_account = accounts(:loan)

    # Clean up existing entries/transactions from fixtures to ensure test isolation
    @family.accounts.each { |account| account.entries.delete_all }

    @search = Transaction::Search.new(@family)
  end

  test "computes basic expense and income totals" do
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

    totals = Transaction::Totals.compute(@search)

    assert_equal 2, totals.transactions_count
    assert_equal Money.new(100, "USD"), totals.expense_money # $100
    assert_equal Money.new(200, "USD"), totals.income_money  # $200
  end



  test "handles multi-currency transactions with exchange rates" do
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

    totals = Transaction::Totals.compute(@search)

    assert_equal 2, totals.transactions_count
    # EUR 100 * 1.1 + USD 50 = 110 + 50 = 160
    assert_equal Money.new(160, "USD"), totals.expense_money
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "handles missing exchange rates gracefully" do
    # Create EUR transaction without exchange rate
    eur_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      currency: "EUR",
      kind: "standard"
    )

    totals = Transaction::Totals.compute(@search)

    assert_equal 1, totals.transactions_count
    # Should use rate of 1 when exchange rate is missing
    assert_equal Money.new(100, "USD"), totals.expense_money # EUR 100 * 1
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "respects category filters" do
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
    totals = Transaction::Totals.compute(search)

    assert_equal 1, totals.transactions_count
    assert_equal Money.new(100, "USD"), totals.expense_money # Only food transaction
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "respects type filters" do
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
    totals = Transaction::Totals.compute(search)

    assert_equal 1, totals.transactions_count
    assert_equal Money.new(100, "USD"), totals.expense_money
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "handles empty results" do
    totals = Transaction::Totals.compute(@search)

    assert_equal 0, totals.transactions_count
    assert_equal Money.new(0, "USD"), totals.expense_money
    assert_equal Money.new(0, "USD"), totals.income_money
  end

  test "respects excluded transactions filter from search" do
    # Create an excluded transaction (should be excluded by default)
    excluded_entry = create_transaction(
      account: @checking_account,
      amount: 100,
      kind: "standard"
    )
    excluded_entry.update!(excluded: true) # Marks it as excluded

    # Create a normal transaction
    normal_entry = create_transaction(
      account: @checking_account,
      amount: 50,
      kind: "standard"
    )

    # Default behavior should exclude excluded transactions
    totals = Transaction::Totals.compute(@search)

    assert_equal 1, totals.transactions_count
    assert_equal Money.new(50, "USD"), totals.expense_money # Only non-excluded transaction

    # Explicitly include excluded transactions
    search_with_excluded = Transaction::Search.new(@family, filters: { excluded_transactions: true })
    totals_with_excluded = Transaction::Totals.compute(search_with_excluded)

    assert_equal 2, totals_with_excluded.transactions_count
    assert_equal Money.new(150, "USD"), totals_with_excluded.expense_money # Both transactions
  end
end
