module Account::Transaction::Provideable
  extend ActiveSupport::Concern

  EnrichmentData = Data.define(:name, :icon_url, :category)

  def enrich_transaction(description, amount: nil, date: nil, city: nil, state: nil, country: nil)
    raise "Provider must implement #enrich_transaction"
  end
end
