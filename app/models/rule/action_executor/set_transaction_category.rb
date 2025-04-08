class Rule::ActionExecutor::SetTransactionCategory < Rule::ActionExecutor
  def type
    "select"
  end

  def options
    family.categories.pluck(:name, :id)
  end

  def execute(transaction_scope, value = nil)
    transaction_scope.update_all(
      category_id: value,
      updated_at: Time.current
    )
  end
end
