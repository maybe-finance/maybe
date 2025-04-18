class Family::AutoCategorizer
  Error = Class.new(StandardError)

  def initialize(family, transaction_ids: [])
    @family = family
    @transaction_ids = transaction_ids
  end

  def auto_categorize
    raise Error, "No LLM provider for auto-categorization" unless llm_provider

    if scope.none?
      Rails.logger.info("No transactions to auto-categorize for family #{family.id}")
      return
    else
      Rails.logger.info("Auto-categorizing #{scope.count} transactions for family #{family.id}")
    end

    result = llm_provider.auto_categorize(
      transactions: transactions_input,
      user_categories: user_categories_input
    )

    unless result.success?
      Rails.logger.error("Failed to auto-categorize transactions for family #{family.id}: #{result.error.message}")
      return
    end

    scope.each do |transaction|
      transaction.lock!(:category_id)

      auto_categorization = result.data.find { |c| c.transaction_id == transaction.id }

      category_id = user_categories_input.find { |c| c[:name] == auto_categorization&.category_name }&.dig(:id)

      if category_id.present?
        Family.transaction do
          transaction.log_enrichment!(
            attribute_name: "category_id",
            attribute_value: category_id,
            source: "ai",
          )

          transaction.update!(category_id: category_id)
        end
      end
    end
  end

  private
    attr_reader :family, :transaction_ids

    # For now, OpenAI only, but this should work with any LLM concept provider
    def llm_provider
      Provider::Registry.get_provider(:openai)
    end

    def user_categories_input
      family.categories.map do |category|
        {
          id: category.id,
          name: category.name,
          is_subcategory: category.subcategory?,
          parent_id: category.parent_id,
          classification: category.classification
        }
      end
    end

    def transactions_input
      scope.map do |transaction|
        {
          id: transaction.id,
          amount: transaction.entry.amount.abs,
          classification: transaction.entry.classification,
          description: transaction.entry.name,
          merchant: transaction.merchant&.name,
          hint: transaction.plaid_category_detailed
        }
      end
    end

    def scope
      family.transactions.where(id: transaction_ids, category_id: nil)
                         .enrichable(:category_id)
                         .includes(:category, :merchant, :entry)
    end
end
