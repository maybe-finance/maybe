class Rule::ActionExecutor::SetTransactionCategory < Rule::ActionExecutor
  def type
    "select"
  end

  def options
    family.categories.pluck(:name, :id)
  end

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false)
    category = family.categories.find_by_id(value)

    scope = transaction_scope

    unless ignore_attribute_locks
      scope = scope.enrichable(:category_id)
    end

    scope.each do |txn|
      txn.update!(category: category)

      de = DataEnrichment.find_or_create_by!(
        enrichable: txn,
        attribute_name: "category_id",
        value: category.id,
        source: "rule"
      )

      de.value = category.id
      de.save!
    end
  end
end
