module Account::Transaction::Provided
  extend ActiveSupport::Concern

  def fetch_enrichment_info
    return nil unless Providers.synth # Only Synth can provide this data

    Providers.synth.enrich_transaction(
      entry.name,
      amount: entry.amount,
      date: entry.date
    )
  end
end
