class Rule::ActionExecutor::SetTransactionTags < Rule::ActionExecutor
  def type
    "select"
  end

  def options
    family.tags.pluck(:name, :id)
  end

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false)
    tag = family.tags.find_by_id(value)

    scope = transaction_scope

    unless ignore_attribute_locks
      scope = scope.enrichable(:tag_ids)
    end

    rows = scope.each do |txn|
      txn.enrich_attribute(
        :tag_ids,
        [ tag.id ],
        source: "rule"
      )
    end
  end
end
