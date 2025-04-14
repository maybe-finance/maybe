module Transaction::Provided
  extend ActiveSupport::Concern

  def fetch_enrichment_info
    return nil unless provider

    response = provider.enrich_transaction(
      entry.name,
      amount: entry.amount,
      date: entry.date
    )

    response.data
  end

  private
    def provider
      Provider::Registry.get_provider(:synth)
    end
end
