class Account::DataEnricher
  include Providable

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def run
    enrich_transactions
  end

  private
    def enrich_transactions
      candidates = account.entries.account_transactions

      Rails.logger.info("Enriching #{candidates.count} transactions for account #{account.id}")

      merchants = {}
      categories = {}

      candidates.each do |entry|
        if entry.enriched_at.nil? || entry.merchant_id.nil? || entry.category_id.nil?
          begin
            info = self.class.synth_provider.enrich_transaction(entry.name).info

            if info.name.present?
              merchant = merchants[info.name] ||= account.family.merchants.find_or_create_by(name: info.name)

              if info.icon_url.present?
                merchant.icon_url = info.icon_url
              end
            end

            if info.category.present?
              category = categories[info.category] ||= account.family.categories.find_or_create_by(name: info.category)
            end

            entryable_attributes = { id: entry.entryable_id }
            entryable_attributes[:merchant_id] = merchant.id if merchant.present?
            entryable_attributes[:category_id] = category.id if category.present?

            Account.transaction do
              merchant.save! if merchant.present?
              category.save! if category.present?
              entry.update!(
                enriched_at: Time.current,
                enriched_name: info.name,
                entryable_attributes: entryable_attributes
              )
            end
          rescue => e
            Rails.logger.warn("Error enriching transaction #{entry.id}: #{e.message}")
          end
        end
      end
    end
end
