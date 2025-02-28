require "test_helper"

class PromptableTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    @balance_sheet = BalanceSheet.new(@family)
    @income_statement = IncomeStatement.new(@family)
  end

  test "models include the Promptable module" do
    assert_includes BalanceSheet.included_modules, Promptable
    assert_includes IncomeStatement.included_modules, Promptable
  end

  test "models respond to to_ai_readable_hash" do
    assert_respond_to @balance_sheet, :to_ai_readable_hash
    assert_respond_to @income_statement, :to_ai_readable_hash
  end

  test "balance_sheet returns a hash with financial data" do
    result = @balance_sheet.to_ai_readable_hash

    assert_kind_of Hash, result
    assert_includes result.keys, :net_worth
    assert_includes result.keys, :total_assets
    assert_includes result.keys, :total_liabilities
    assert_includes result.keys, :as_of_date
    assert_includes result.keys, :currency
  end

  test "income_statement returns a hash with financial data" do
    result = @income_statement.to_ai_readable_hash

    assert_kind_of Hash, result
    assert_includes result.keys, :total_income
    assert_includes result.keys, :total_expenses
    assert_includes result.keys, :net_income
    assert_includes result.keys, :savings_rate
    assert_includes result.keys, :period
    assert_includes result.keys, :currency
  end
end
