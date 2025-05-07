class Rule::ActionExecutor::AutoCategorize < Rule::ActionExecutor
  def label
    if rule.family.self_hoster?
      "Auto-categorize transactions with AI ($$)"
    else
      "Auto-categorize transactions"
    end
  end

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false)
    enrichable_transactions = transaction_scope.enrichable(:category_id)

    if enrichable_transactions.empty?
      Rails.logger.info("No transactions to auto-categorize for #{rule.id}")
      return
    end

    enrichable_transactions.in_batches(of: 20).each_with_index do |transactions, idx|
      Rails.logger.info("Scheduling auto-categorization for batch #{idx + 1} of #{enrichable_transactions.count}")
      rule.family.auto_categorize_transactions_later(transactions)
    end
  end
end
