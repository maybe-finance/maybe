require "test_helper"

class IncomeStatementTest < ActiveSupport::TestCase
  include EntriesTestHelper

  setup do
    @family = families(:empty)

    @income_category = @family.categories.create! name: "Income", classification: "income"
    @food_category = @family.categories.create! name: "Food", classification: "expense"
    @groceries_category = @family.categories.create! name: "Groceries", classification: "expense", parent: @food_category

    @checking_account = @family.accounts.create! name: "Checking", currency: @family.currency, balance: 5000, accountable: Depository.new
    @credit_card_account = @family.accounts.create! name: "Credit Card", currency: @family.currency, balance: 1000, accountable: CreditCard.new

    create_transaction(account: @checking_account, amount: -1000, category: @income_category)
    create_transaction(account: @checking_account, amount: 200, category: @groceries_category)
    create_transaction(account: @credit_card_account, amount: 300, category: @groceries_category)
    create_transaction(account: @credit_card_account, amount: 400, category: @groceries_category)
  end

  test "calculates totals for transactions" do
    income_statement = IncomeStatement.new(@family)
    assert_equal Money.new(1000, @family.currency), income_statement.totals.income_money
    assert_equal Money.new(200 + 300 + 400, @family.currency), income_statement.totals.expense_money
    assert_equal 4, income_statement.totals.transactions_count
  end

  test "calculates expenses for a period" do
    income_statement = IncomeStatement.new(@family)
    expense_totals = income_statement.expense_totals(period: Period.last_30_days)

    expected_total_expense = 200 + 300 + 400

    assert_equal expected_total_expense, expense_totals.total
    assert_equal expected_total_expense, expense_totals.category_totals.find { |ct| ct.category.id == @groceries_category.id }.total
    assert_equal expected_total_expense, expense_totals.category_totals.find { |ct| ct.category.id == @food_category.id }.total
  end

  test "calculates income for a period" do
    income_statement = IncomeStatement.new(@family)
    income_totals = income_statement.income_totals(period: Period.last_30_days)

    expected_total_income = 1000

    assert_equal expected_total_income, income_totals.total
    assert_equal expected_total_income, income_totals.category_totals.find { |ct| ct.category.id == @income_category.id }.total
  end

  test "calculates median expense" do
    income_statement = IncomeStatement.new(@family)
    assert_equal 200 + 300 + 400, income_statement.expense_totals(period: Period.last_30_days).total
  end

  test "calculates median income" do
    income_statement = IncomeStatement.new(@family)
    assert_equal 1000, income_statement.income_totals(period: Period.last_30_days).total
  end
end
