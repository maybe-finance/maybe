module Account::Enrichable
  extend ActiveSupport::Concern

  def enrich_data
    DataEnricher.new(self).run
  end

  private
    def enrichable?
      family.data_enrichment_enabled? || (linked? && Rails.application.config.app_mode.hosted?)
    end
end
