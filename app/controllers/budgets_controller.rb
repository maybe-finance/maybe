class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[show edit update copy_previous]

  def index
    redirect_to_current_month_budget
  end

  def show
  end

  def edit
    render layout: "wizard"
  end

  def update
    @budget.update!(budget_params)
    redirect_to budget_budget_categories_path(@budget)
  end

  def copy_previous
    prev_date = @budget.start_date - 1.month
    previous_budget = Current.family.budgets.find_by(start_date: prev_date.beginning_of_month)

    if previous_budget
      @budget.copy_from!(previous_budget)
      notice = "Budget copied from #{previous_budget.name}"
      redirect_to budget_budget_categories_path(@budget), notice: notice
    else
      redirect_to budget_budget_categories_path(@budget), alert: "Previous month's budget not found"
    end
  end

  def picker
    render partial: "budgets/picker", locals: {
      family: Current.family,
      year: params[:year].to_i || Date.current.year
    }
  end

  private

    def budget_create_params
      params.require(:budget).permit(:start_date)
    end

    def budget_params
      params.require(:budget).permit(:budgeted_spending, :expected_income)
    end

    def set_budget
      start_date = Budget.param_to_date(params[:month_year])
      @budget = Budget.find_or_bootstrap(Current.family, start_date: start_date)
      raise ActiveRecord::RecordNotFound unless @budget
    end

    def redirect_to_current_month_budget
      current_budget = Budget.find_or_bootstrap(Current.family, start_date: Date.current)
      redirect_to budget_path(current_budget)
    end
end
