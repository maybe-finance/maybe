module Account::Enrichable
  extend ActiveSupport::Concern

  def enrich_data
    total_unenriched = entries.transactions
      .joins("JOIN transactions at ON at.id = entries.entryable_id AND entries.entryable_type = 'Transaction'")
      .where("entries.enriched_at IS NULL OR at.merchant_id IS NULL OR at.category_id IS NULL")
      .count

    if total_unenriched > 0
      batch_size = 50
      batches = (total_unenriched.to_f / batch_size).ceil

      batches.times do |batch|
        EnrichTransactionBatchJob.perform_now(self, batch_size, batch * batch_size)
        # EnrichTransactionBatchJob.perform_later(self, batch_size, batch * batch_size)
      end
    end
  end

  def enrich_transaction_batch(batch_size = 50, offset = 0)
    transactions_batch = enrichable_transactions.offset(offset).limit(batch_size)

    Rails.logger.info("Enriching batch of #{transactions_batch.count} transactions for account #{id} (offset: #{offset})")

    merchants = {}

    transactions_batch.each do |transaction|
      begin
        info = transaction.fetch_enrichment_info

        next unless info.present?

        if info.name.present?
          merchant = merchants[info.name] ||= family.merchants.find_or_create_by(name: info.name)

          if info.icon_url.present?
            merchant.icon_url = info.icon_url
          end
        end

        Account.transaction do
          merchant.save! if merchant.present?
          transaction.update!(merchant: merchant) if merchant.present? && transaction.merchant_id.nil?

          transaction.entry.update!(
            enriched_at: Time.current,
            enriched_name: info.name,
          )
        end
      rescue => e
        Rails.logger.warn("Error enriching transaction #{transaction.id}: #{e.message}")
      end
    end
  end

  private
    def enrichable?
      family.data_enrichment_enabled? || (linked? && Rails.application.config.app_mode.hosted?)
    end

    def enrichable_transactions
      transactions.active
                  .includes(:merchant, :category)
                  .where(
                    "entries.enriched_at IS NULL",
                    "OR merchant_id IS NULL",
                    "OR category_id IS NULL"
                  )
    end
end
