class Rule::ActionExecutor::AiAutoCategorize < Rule::ActionExecutor
  ProviderMissingError = Class.new(StandardError)

  def execute(transaction_scope, value: nil, ignore_attribute_locks: false)
    raise ProviderMissingError, "LLM provider is not configured" unless llm_provider.present?

    enrichable_transactions = transaction_scope.enrichable(:category_id).where(category_id: nil).includes(:category, :merchant, :entry)

    if enrichable_transactions.none?
      Rails.logger.info("No transactions to auto-categorize for rule #{rule.id}")
      return
    else
      Rails.logger.info("Auto-categorizing #{enrichable_transactions.count} transactions for rule #{rule.id}")
    end

    consecutive_failures = 0
    total_transactions = enrichable_transactions.count
    batch_size = 100
    total_batches = (total_transactions.to_f / batch_size).ceil
    batch_index = 0

    enrichable_transactions.in_batches(of: batch_size, load: true) do |batch|
      batch_index += 1
      percent_complete = ((batch_index.to_f / total_batches) * 100).round
      Rails.logger.info("Processing batch #{batch_index} of #{total_batches} (#{percent_complete}% complete) for rule #{rule.id}")
      success = process_batch(batch)
      if success
        consecutive_failures = 0
      else
        consecutive_failures += 1
        break if consecutive_failures >= 3
      end
    end
  end

  private
    def llm_provider
      rule.llm_provider
    end

    def process_batch(batch)
      result = llm_provider.auto_categorize(
        transactions: prepare_transaction_input(batch),
        user_categories: user_categories
      )

      unless result.success?
        Rails.logger.error("Failed to auto-categorize transactions for rule #{rule.id}: #{result.error.message}")
        return false
      end

      batch.each do |txn|
        txn.lock!(:category_id)

        auto_categorization = result.data.find { |c| c.transaction_id == txn.id }

        if auto_categorization.present?
          category_id = user_categories.find { |c| c[:name] == auto_categorization.category_name }&.dig(:id)

          if category_id.present?
            DataEnrichment.transaction do
              de = DataEnrichment.find_or_create_by!(
                enrichable: txn,
                attribute_name: "category_id",
                value: category_id,
                source: "rule"
              )

              de.value = category_id
              de.save!

              txn.update!(category_id: category_id)
            end
          end
        end
      end

      true
    end

    def prepare_transaction_input(transactions)
      transactions.map do |transaction|
        {
          id: transaction.id,
          amount: transaction.entry.amount.abs,
          classification: transaction.entry.classification,
          description: transaction.entry.name,
          merchant: transaction.merchant&.name
        }
      end
    end

    def user_categories
      rule.family.categories.map do |category|
        {
          id: category.id,
          name: category.name,
          is_subcategory: category.subcategory?,
          parent_id: category.parent_id,
          classification: category.classification
        }
      end
    end
end
