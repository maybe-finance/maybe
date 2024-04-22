module ValueGroupsHelper
  def value_group_pie_data(value_group)
    value_group.children
      .map do |child|
        {
          label: to_accountable_title(Accountable.from_type(child.name)),
          percent_of_total: child.percent_of_total.round(1).to_f,
          value: child.sum.amount.to_f,
          currency: child.sum.currency.iso_code,
          bg_color: accountable_bg_class(child.name),
          fill_color: accountable_fill_class(child.name)
        }
      end
      .filter { |child| child[:value] > 0 }
      .to_json
  end
end
