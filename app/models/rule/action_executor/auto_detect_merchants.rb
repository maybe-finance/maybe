class Rule::ActionExecutor::AutoDetectMerchants < Rule::ActionExecutor
  def label
    if rule.family.self_hoster?
      "Auto-detect merchants with AI ($$)"
    else
      "Auto-detect merchants"
    end
  end

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false)
    enrichable_transactions = transaction_scope.enrichable(:merchant_id)

    if enrichable_transactions.empty?
      Rails.logger.info("No transactions to auto-detect merchants for #{rule.title} #{rule.id}")
      return
    end

    enrichable_transactions.in_batches(of: 20).each_with_index do |transactions, idx|
      Rails.logger.info("Scheduling auto-merchant-enrichment for batch #{idx + 1} of #{enrichable_transactions.count}")
      rule.family.auto_detect_transaction_merchants_later(transactions)
    end
  end
end
