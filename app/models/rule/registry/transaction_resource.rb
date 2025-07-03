class Rule::Registry::TransactionResource < Rule::Registry
  def resource_scope
    family.transactions.visible.with_entry.where(entry: { date: rule.effective_date.. })
  end

  def condition_filters
    [
      Rule::ConditionFilter::TransactionName.new(rule),
      Rule::ConditionFilter::TransactionAmount.new(rule),
      Rule::ConditionFilter::TransactionMerchant.new(rule)
    ]
  end

  def action_executors
    enabled_executors = [
      Rule::ActionExecutor::SetTransactionCategory.new(rule),
      Rule::ActionExecutor::SetTransactionTags.new(rule),
      Rule::ActionExecutor::SetTransactionMerchant.new(rule),
      Rule::ActionExecutor::SetTransactionName.new(rule)
    ]

    if ai_enabled?
      enabled_executors << Rule::ActionExecutor::AutoCategorize.new(rule)
      enabled_executors << Rule::ActionExecutor::AutoDetectMerchants.new(rule)
    end

    enabled_executors
  end

  private
    def ai_enabled?
      Provider::Registry.get_provider(:openai).present?
    end
end
