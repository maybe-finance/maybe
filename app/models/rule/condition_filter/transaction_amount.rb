class Rule::ConditionFilter::TransactionAmount < Rule::ConditionFilter
  def type
    "number"
  end

  def prepare(scope)
    scope.with_entry
  end

  def apply(scope, operator, value)
    expression = build_sanitized_where_condition("ABS(entries.amount)", operator, value.to_d)
    scope.where(expression)
  end
end
