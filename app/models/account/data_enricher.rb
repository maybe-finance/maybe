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
      candidates = account.entries.account_transactions.includes(entryable: [ :merchant, :category ])

      Rails.logger.info("Enriching #{candidates.count} transactions for account #{account.id}")

      merchants = {}

      candidates.each do |entry|
        if entry.enriched_at.nil? || entry.entryable.merchant_id.nil? || entry.entryable.category_id.nil?
          begin
            next unless entry.name.present?

            info = self.class.synth_provider.enrich_transaction(entry.name).info

            next unless info.present?

            if info.name.present?
              merchant = merchants[info.name] ||= account.family.merchants.find_or_create_by(name: info.name)

              if info.icon_url.present?
                merchant.icon_url = info.icon_url
              end
            end

            entryable_attributes = { id: entry.entryable_id }
            entryable_attributes[:merchant_id] = merchant.id if merchant.present? && entry.entryable.merchant_id.nil?

            Account.transaction do
              merchant.save! if merchant.present?
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
