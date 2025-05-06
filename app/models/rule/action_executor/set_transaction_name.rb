class Rule::ActionExecutor::SetTransactionName < Rule::ActionExecutor
  def type
    "text"
  end

  def options
    nil
  end

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false)
    return if value.blank?

    scope = transaction_scope
    unless ignore_attribute_locks
      scope = scope.enrichable(:name)
    end

    scope.each do |txn|
      Rule.transaction do
        txn.entry.log_enrichment!(
          attribute_name: "name",
          attribute_value: value,
          source: "rule"
        )
        txn.entry.update!(name: value)
      end
    end
  end
end
