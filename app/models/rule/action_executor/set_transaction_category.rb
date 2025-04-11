class Rule::ActionExecutor::SetTransactionCategory < Rule::ActionExecutor
  def type
    "select"
  end

  def options
    family.categories.pluck(:name, :id)
  end

  def execute(transaction_scope, value = nil)
    category = family.categories.find_by_id(value)

    transaction_scope.attributes_unlocked(:category_id).update_all(
      category_id: category.id,
      updated_at: Time.current
    )
  end
end
