module ValueGroupsHelper
  def value_group_pie_data(value_group)
    values = value_group.children
      .map do |child|
        {
          label: to_accountable_title(Accountable.from_type(child.name)),
          percent_of_total: child.percent_of_total.round(1).to_f,
          value: child.sum.amount.to_f,
          currency: child.sum.currency.iso_code,
          formatted_value: format_money(child.sum.amount.to_f, precision: 2, unit: child.sum.currency.symbol, separator: ".", delimiter: ","),
          bg_color: accountable_bg_class(child.name),
          fill_color: accountable_fill_class(child.name)
        }
      end
      .filter { |child| child[:value] > 0 }

    total = values.sum { |child| child[:value] }
    formatted_total = format_money(total, precision: 2, unit: value_group.sum.currency.symbol, separator: ".", delimiter: ",")

    {
      values: values,
      total: total,
      formatted_total: formatted_total,
    }.to_json

  end
end
