class BudgetsController < ApplicationController
  before_action :set_budget, only: %i[show edit update]

  def index
    redirect_to_current_month_budget
  end

  def show
    render layout: with_sidebar
  end

  def edit
  end

  def update
  end

  def picker
    render partial: "budgets/picker", locals: {
      family: Current.family,
      year: params[:year].to_i || Date.current.year
    }
  end

  private
    def set_budget
      @budget = Current.family.budgets.find(params[:id])
    end

    def redirect_to_current_month_budget
      current_budget = Current.family.budgets.current
      redirect_to budget_path(current_budget)
    end
end
