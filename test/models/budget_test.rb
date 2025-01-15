require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  test "over allocated if allocations greater than budgeted amount" do
    budget = budgets(:one)

    budget_category = budget.budget_categories.create!(
      category: categories(:food_and_drink),
      budgeted_spending: 10000,
      currency: "USD"
    )

    assert budget.over_allocated?
  end
end
