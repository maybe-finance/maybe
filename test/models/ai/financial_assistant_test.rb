require "test_helper"

class Ai::FinancialAssistantTest < ActiveSupport::TestCase
  setup do
    @family = families(:dylan_family)
    mock_client = Object.new
    @financial_assistant = Ai::FinancialAssistant.new(@family, client: mock_client)
  end

  test "initializes with a family" do
    assert_equal @family, @financial_assistant.family
  end

  test "responds to query method" do
    assert_respond_to @financial_assistant, :query
  end

  test "defines financial function definitions" do
    assert_respond_to @financial_assistant, :financial_function_definitions

    definitions = @financial_assistant.financial_function_definitions
    assert_kind_of Array, definitions

    # Check if it includes get_balance_sheet function
    get_balance_sheet = definitions.find { |d| d[:name] == "get_balance_sheet" }
    assert_not_nil get_balance_sheet

    # Check if it includes get_income_statement function
    get_income_statement = definitions.find { |d| d[:name] == "get_income_statement" }
    assert_not_nil get_income_statement
  end
end
