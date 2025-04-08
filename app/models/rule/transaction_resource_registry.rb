class Rule::TransactionResourceRegistry
  def initialize(rule)
    @rule = rule
  end

  def scope
    family.transactions.active
  end

  def get_filter!(key)
    condition_filters.find { |filter| filter.key == key }
  end

  def get_executor!(key)
    action_executors.find { |executor| executor.key == key }
  end

  private
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
