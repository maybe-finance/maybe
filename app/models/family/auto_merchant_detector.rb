class Family::AutoMerchantDetector
  Error = Class.new(StandardError)

  def initialize(family, transaction_ids: [])
    @family = family
    @transaction_ids = transaction_ids
  end

  def auto_detect
    raise "No LLM provider for auto-detecting merchants" unless llm_provider

    if scope.none?
      Rails.logger.info("No transactions to auto-detect merchants for family #{family.id}")
      return
    else
      Rails.logger.info("Auto-detecting merchants for #{scope.count} transactions for family #{family.id}")
    end

    result = llm_provider.auto_detect_merchants(
      transactions: transactions_input,
      user_merchants: user_merchants_input
    )

    unless result.success?
      Rails.logger.error("Failed to auto-detect merchants for family #{family.id}: #{result.error.message}")
      return
    end

    scope.each do |transaction|
      transaction.lock!(:merchant_id)

      auto_detection = result.data.find { |c| c.transaction_id == transaction.id }

      merchant_id = user_merchants_input.find { |m| m[:name] == auto_detection&.business_name }&.dig(:id)

      if merchant_id.nil? && auto_detection&.business_url.present? && auto_detection&.business_name.present?
        ai_provider_merchant = ProviderMerchant.find_or_create_by!(
          source: "ai",
          name: auto_detection.business_name,
          website_url: auto_detection.business_url,
        ) do |pm|
          pm.logo_url = "#{default_logo_provider_url}/#{auto_detection.business_url}"
        end
      end

      merchant_id = merchant_id || ai_provider_merchant&.id

      if merchant_id.present?
        Family.transaction do
          transaction.log_enrichment!(
            attribute_name: "merchant_id",
            attribute_value: merchant_id,
            source: "ai",
          )

          transaction.update!(merchant_id: merchant_id)
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

    def default_logo_provider_url
      "https://logo.synthfinance.com"
    end

    def user_merchants_input
      family.merchants.map do |merchant|
        {
          id: merchant.id,
          name: merchant.name
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
          merchant: transaction.merchant&.name
        }
      end
    end

    def scope
      family.transactions.where(id: transaction_ids, merchant_id: nil)
                         .enrichable(:merchant_id)
                         .includes(:merchant, :entry)
    end
end
