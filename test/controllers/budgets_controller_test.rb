require "test_helper"

class BudgetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:family_admin)
  end

  test "copy previous" do
    current_budget = budgets(:one)
    previous_budget = budgets(:previous)

    post copy_previous_budget_url(current_budget)
    assert_redirected_to budget_budget_categories_url(current_budget)

    current_budget.reload
    assert_equal previous_budget.budgeted_spending, current_budget.budgeted_spending
    assert_equal previous_budget.expected_income, current_budget.expected_income

    prev_bc = previous_budget.budget_categories.find_by(category: categories(:food_and_drink))
    curr_bc = current_budget.budget_categories.find_by(category: categories(:food_and_drink))
    assert_equal prev_bc.budgeted_spending, curr_bc.budgeted_spending
  end
end