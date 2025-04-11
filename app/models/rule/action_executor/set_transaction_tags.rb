class Rule::ActionExecutor::SetTransactionTags < Rule::ActionExecutor
  def type
    "select"
  end

  def options
    family.tags.pluck(:name, :id)
  end

  def execute(transaction_scope, value = nil)
    tag = family.tags.find_by_id(value)

    transaction_scope.each do |transaction|
      transaction.update(tags: [ tag ])
    end
  end
end
