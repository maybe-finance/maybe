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
      Rule.transaction do
        txn.log_enrichment!(
          attribute_name: "category_id",
          attribute_value: category.id,
          source: "rule"
        )

        txn.update!(category: category)
      end
    end
  end
end
