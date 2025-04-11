module BudgetsHelper
  def is_budgeted_tab?
    params[:tab].presence == "budgeted"
  end

  def is_actuals_tab?
    params[:tab].presence == "actuals"
  end
end
