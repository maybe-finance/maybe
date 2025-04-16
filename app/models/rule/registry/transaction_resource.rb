class Rule::Registry::TransactionResource < Rule::Registry
  def resource_scope
    family.transactions.active.with_entry.where(entry: { date: rule.effective_date.. })
  end

  def condition_filters
    [
      Rule::ConditionFilter::TransactionName.new(rule),
      Rule::ConditionFilter::TransactionAmount.new(rule),
      Rule::ConditionFilter::TransactionMerchant.new(rule)
    ]
  end

  def action_executors
    [
      Rule::ActionExecutor::SetTransactionCategory.new(rule),
      Rule::ActionExecutor::SetTransactionTags.new(rule),
      Rule::ActionExecutor::AiEnhanceTransactionName.new(rule),
      Rule::ActionExecutor::AiAutoCategorize.new(rule)
    ]
  end
end
