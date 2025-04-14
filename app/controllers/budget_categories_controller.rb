class BudgetCategoriesController < ApplicationController
  before_action :set_budget

  def index
    @budget_categories = @budget.budget_categories.includes(:category)
    render layout: "wizard"
  end

  def show
    @recent_transactions = @budget.transactions

    if params[:id] == BudgetCategory.uncategorized.id
      @budget_category = @budget.uncategorized_budget_category
      @recent_transactions = @recent_transactions.where(transactions: { category_id: nil })
    else
      @budget_category = Current.family.budget_categories.find(params[:id])
      @recent_transactions = @recent_transactions.joins("LEFT JOIN categories ON categories.id = transactions.category_id")
                                                 .where("categories.id = ? OR categories.parent_id = ?", @budget_category.category.id, @budget_category.category.id)
    end

    @recent_transactions = @recent_transactions.order("entries.date DESC, ABS(entries.amount) DESC").take(3)
  end

  def update
    @budget_category = Current.family.budget_categories.find(params[:id])

    if @budget_category.update(budget_category_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to budget_budget_categories_path(@budget) }
      end
    else
      render :index, status: :unprocessable_entity
    end
  end

  private
    def budget_category_params
      params.require(:budget_category).permit(:budgeted_spending).tap do |params|
        params[:budgeted_spending] = params[:budgeted_spending].presence || 0
      end
    end

    def set_budget
      start_date = Budget.param_to_date(params[:budget_month_year])
      @budget = Current.family.budgets.find_by(start_date: start_date)
    end
end
