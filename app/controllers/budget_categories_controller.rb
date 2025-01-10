class BudgetCategoriesController < ApplicationController
  def index
    @budget = Current.family.budgets.find(params[:budget_id])

    @budget_categories = Current.family.categories.expenses.map do |category|
      @budget.budget_categories.find_or_create_by(category: category) do |budget_category|
        budget_category.budgeted_amount = 0
        budget_category.currency = @budget.currency
      end
    end

    render layout: "wizard"
  end

  def show
    @budget_category = Current.family.budget_categories.find(params[:id])
  end

  def update
  end
end
