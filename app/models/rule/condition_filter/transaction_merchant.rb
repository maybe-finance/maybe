class Rule::ConditionFilter::TransactionMerchant < Rule::ConditionFilter
  def type
    "select"
  end

  def options
    family.assigned_merchants.pluck(:name, :id)
  end

  def prepare(scope)
    scope.left_joins(:merchant)
  end

  def apply(scope, operator, value)
    expression = build_sanitized_where_condition("merchants.id", operator, value)
    scope.where(expression)
  end
end
