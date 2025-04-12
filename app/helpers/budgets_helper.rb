module BudgetsHelper
  # defaults to actuals tab
  def is_actuals_tab?
    params[:tab].blank? || params[:tab] == "actuals"
  end

  def is_budgeted_tab?
    params[:tab] == "budgeted"
  end
end
