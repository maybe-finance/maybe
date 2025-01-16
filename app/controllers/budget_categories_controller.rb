class BudgetCategoriesController < ApplicationController
  def index
    @budget = Current.family.budgets.find(params[:budget_id])
    render layout: "wizard"
  end

  def show
    @budget = Current.family.budgets.find(params[:budget_id])

    @recent_transactions = @budget.entries

    if params[:id] == BudgetCategory.uncategorized.id
      @budget_category = @budget.uncategorized_budget_category
      @recent_transactions = @recent_transactions.where(account_transactions: { category_id: nil })
    else
      @budget_category = Current.family.budget_categories.find(params[:id])
      @recent_transactions = @recent_transactions.where(account_transactions: { category_id: @budget_category.category.id })
    end

    @recent_transactions = @recent_transactions.order("account_entries.date DESC, ABS(account_entries.amount) DESC").take(3)
  end

  def update
    @budget_category = Current.family.budget_categories.find(params[:id])
    @budget_category.update!(budget_category_params)

    redirect_to budget_budget_categories_path(@budget_category.budget)
  end

  private
    def budget_category_params
      params.require(:budget_category).permit(:budgeted_spending)
    end
end
