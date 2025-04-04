module Rule::Condition::Sanitizable
  extend ActiveSupport::Concern

  def build_sanitized_where_condition(field, operator, value)
    sanitized_value = operator == "like" ? ActiveRecord::Base.sanitize_sql_like(value) : value

    ActiveRecord::Base.sanitize_sql_for_conditions([
      "#{field} #{sanitize_operator(operator)} ?",
      sanitized_value
    ])
  end

  def sanitize_operator(operator)
    raise UnsupportedOperatorError, "Unsupported operator: #{operator}" unless Rule::Condition::OPERATORS.include?(operator)
    operator
  end
end
