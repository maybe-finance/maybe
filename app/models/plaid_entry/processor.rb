class PlaidEntry::Processor
  # plaid_transaction is the raw hash fetched from Plaid API and converted to JSONB
  def initialize(plaid_transaction, plaid_account:, category_matcher:)
    @plaid_transaction = plaid_transaction
    @plaid_account = plaid_account
    @category_matcher = category_matcher
  end

  def process
    PlaidAccount.transaction do
      entry = account.entries.find_or_initialize_by(plaid_id: plaid_id) do |e|
        e.entryable = Transaction.new
      end

      entry.assign_attributes(
        amount: amount,
        currency: currency,
        date: date
      )

      entry.enrich_attribute(
        :name,
        name,
        source: "plaid"
      )

      if detailed_category
        matched_category = category_matcher.match(detailed_category)

        if matched_category
          entry.transaction.enrich_attribute(
            :category_id,
            matched_category.id,
            source: "plaid"
          )
        end
      end

      if merchant
        entry.transaction.enrich_attribute(
          :merchant_id,
          merchant.id,
          source: "plaid"
        )
      end
    end
  end

  private
    attr_reader :plaid_transaction, :plaid_account, :category_matcher

    def account
      plaid_account.account
    end

    def plaid_id
      plaid_transaction["transaction_id"]
    end

    def name
      plaid_transaction["merchant_name"] || plaid_transaction["original_description"]
    end

    def amount
      plaid_transaction["amount"]
    end

    def currency
      plaid_transaction["iso_currency_code"]
    end

    def date
      plaid_transaction["date"]
    end

    def detailed_category
      plaid_transaction.dig("personal_finance_category", "detailed")
    end

    def merchant
      merchant_id = plaid_transaction["merchant_entity_id"]
      merchant_name = plaid_transaction["merchant_name"]

      return nil unless merchant_id.present? && merchant_name.present?

      ProviderMerchant.find_or_create_by!(
        source: "plaid",
        name: merchant_name,
      ) do |m|
        m.provider_merchant_id = merchant_id
        m.website_url = plaid_transaction["website"]
        m.logo_url = plaid_transaction["logo_url"]
      end
    end
end
