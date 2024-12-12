class Account::DataEnricher
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def run
    enrich_transactions
  end

  private
    def enrich_transactions
      candidates = account.entries.account_transactions.where(enriched_at: nil)

      Rails.logger.info("Enriching #{candidates.count} transactions for account #{account.id}")

      candidates.each(&:enrich)
    end
end
