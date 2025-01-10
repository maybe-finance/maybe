class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[show edit update]

  def index
    redirect_to_current_month_budget
  end

  def show
    @next_budget = @budget.next_budget(Current.family.currency)
    @previous_budget = @budget.previous_budget(Current.family.currency)
    @latest_budget = Current.family.budgets.current(Current.family.currency)
    render layout: with_sidebar
  end

  def edit
    render layout: "wizard"
  end

  def update
    @budget.update!(budget_params)
    redirect_to budget_budget_categories_path(@budget)
  end

  def picker
    render partial: "budgets/picker", locals: {
      family: Current.family,
      year: params[:year].to_i || Date.current.year
    }
  end

  private
    def budget_params
      params.require(:budget).permit(:budgeted_amount, :expected_income)
    end

    def set_budget
      @budget = Current.family.budgets.find(params[:id])
    end

    def redirect_to_current_month_budget
      current_budget = Current.family.budgets.current(Current.family.currency)
      redirect_to budget_path(current_budget)
    end
end
