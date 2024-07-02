module ValueGroupsHelper
  def value_group_pie_data(value_group)
    value_group.children.filter { |child| child.sum > 0 }.map do |child|
      {
        label: to_accountable_title(Accountable.from_type(child.name)),
        percent_of_total: child.percent_of_total.round(1).to_f,
        value: child.sum.amount.to_f,
        formatted_value: format_money(child.sum, precision: 0),
        bg_color: accountable_bg_class(child.name),
        fill_color: accountable_fill_class(child.name)
      }
    end.to_json
  end
end
