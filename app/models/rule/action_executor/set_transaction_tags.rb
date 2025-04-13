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
      DataEnrichment.transaction do
        txn.update!(tag_ids: [ tag.id ])

        de = DataEnrichment.find_or_initialize_by(
          enrichable_id: txn.id,
          enrichable_type: "Account::Transaction",
          attribute_name: "tag_ids",
          source: "rule"
        )

        de.value = [ tag.id ]
        de.save!
      end
    end
  end
end
