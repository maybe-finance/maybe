class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[show edit update]

  def index
    redirect_to_current_month_budget
  end

  def show
    @next_budget = @budget.next_budget
    @previous_budget = @budget.previous_budget
    @latest_budget = Budget.find_or_bootstrap(Current.family)
    render layout: with_sidebar
  end

  def edit
    render layout: "wizard"
  end

  def update
    @budget.update!(budget_params)
    redirect_to budget_budget_categories_path(@budget)
  end

  def create
    start_date = Date.parse(budget_create_params[:start_date])
    @budget = Budget.find_or_bootstrap(Current.family, date: start_date)
    redirect_to budget_path(@budget)
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
      @budget = Current.family.budgets.find(params[:id])
      @budget.sync_budget_categories
    end

    def redirect_to_current_month_budget
      current_budget = Budget.find_or_bootstrap(Current.family)
      redirect_to budget_path(current_budget)
    end
end
