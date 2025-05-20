class Rule::ActionExecutor::SetTransactionMerchant < Rule::ActionExecutor
  def type
    "select"
  end

  def options
    family.merchants.pluck(:name, :id)
  end

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false)
    merchant = family.merchants.find_by_id(value)
    return unless merchant

    scope = transaction_scope
    unless ignore_attribute_locks
      scope = scope.enrichable(:merchant_id)
    end

    scope.each do |txn|
      txn.enrich_attribute(
        :merchant_id,
        merchant.id,
        source: "rule"
      )
    end
  end
end
