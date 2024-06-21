module Account::ValuationsHelper
  def valuation_icon(valuation)
    if valuation.first_of_series?
      "keyboard"
    elsif valuation.trend.direction.up?
      "arrow-up"
    elsif valuation.trend.direction.down?
      "arrow-down"
    else
      "minus"
    end
  end

  def valuation_label(valuation)
    valuation.first_of_series? ? t(".start_balance") : t(".value_update")
  end
end
