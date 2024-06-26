module ValueGroupsHelper
  def value_group_pie_data(value_group)
    values = value_group.children.map do |child|
      {
        label: to_accountable_title(Accountable.from_type(child.name)),
        percent_of_total: child.percent_of_total.round(1).to_f,
        value: child.sum.amount.to_f,
        value_str: {
          fractional_part: child.sum.cents_str,
          main_part: format_money_without_symbol(child.sum.amount.to_f, precision: 0, unit: child.sum.currency.symbol)
        },
        currency: {
          iso_code: child.sum.currency.iso_code,
          symbol: child.sum.currency.symbol,
          displayed_before_value: child.sum.currency.default_format.start_with?("%u")
        },
        bg_color: accountable_bg_class(child.name),
        fill_color: accountable_fill_class(child.name)
      }
    end.filter { |child| child[:value] > 0 }

    total_value = values.sum { |child| child[:value] }
    main_part = format_money_without_symbol(total_value, precision: 0, unit: value_group.sum.currency.symbol)
    fractional_part = Money.new(total_value, value_group.sum.currency).cents_str

    {
      values: values,
      value: total_value,
      value_str: {
        main_part: main_part,
        fractional_part: fractional_part
      },
      currency: {
        iso_code: value_group.sum.currency.iso_code,
        symbol: value_group.sum.currency.symbol,
        displayed_before_value: value_group.sum.currency.default_format.start_with?("%u")
      }
    }.to_json

  end
end
