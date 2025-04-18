class Rule::ConditionFilter::TransactionName < Rule::ConditionFilter
  def prepare(scope)
    scope.with_entry
  end

  def apply(scope, operator, value)
    expression = build_sanitized_where_condition("entries.name", operator, value)
    scope.where(expression)
  end
end
