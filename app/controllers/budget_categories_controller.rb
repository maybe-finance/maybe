class BudgetCategoriesController < ApplicationController
  def index
    @budget = Current.family.budgets.find(params[:budget_id])
    render layout: "wizard"
  end

  def show
    @budget_category = Current.family.budget_categories.find(params[:id])
    @transactions = @budget_category.category.transactions.includes(:entry).where(entry: { date: @budget_category.budget.start_date..@budget_category.budget.end_date }).order(date: :desc)
  end

  def update
    @budget_category = Current.family.budget_categories.find(params[:id])
    @budget_category.update!(budget_category_params)

    redirect_to budget_budget_categories_path(@budget_category.budget)
  end

  private
    def budget_category_params
      params.require(:budget_category).permit(:budgeted_amount)
    end
end
