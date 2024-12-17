class AddEnrichmentSetting < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :data_enrichment_enabled, :boolean, default: false
  end
end
