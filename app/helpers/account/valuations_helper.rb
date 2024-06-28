module Account::ValuationsHelper
  def valuation_icon(valuation, is_oldest: false)
    if is_oldest
      "keyboard"
    elsif valuation.trend.direction.up?
      "arrow-up"
    elsif valuation.trend.direction.down?
      "arrow-down"
    else
      "minus"
    end
  end

  def valuation_style(valuation, is_oldest: false)
    color = is_oldest ? "#D444F1" : valuation.trend.color

    mixed_hex_styles(color)
  end
end
