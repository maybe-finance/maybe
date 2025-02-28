module Account::Entry::Provided
  extend ActiveSupport::Concern

  include Synthable

  def fetch_enrichment_info
    return nil unless synth_client.present?

    synth_client.enrich_transaction(name).info
  end
end
