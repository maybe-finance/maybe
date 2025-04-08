class Rule::ActionExecutor::SetTransactionTags < Rule::ActionExecutor
  def options
    family.tags.pluck(:name, :id)
  end

  def execute(transaction_scope, value = nil)
    # TODO
  end
end
