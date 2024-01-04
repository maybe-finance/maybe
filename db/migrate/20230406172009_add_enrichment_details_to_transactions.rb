class AddEnrichmentDetailsToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :enrichment_country, :string
    add_column :transactions, :enrichment_intermediaries, :jsonb, default: {}
    add_column :transactions, :enrichment_label_group, :string
    add_column :transactions, :enrichment_label, :string
    add_column :transactions, :enrichment_location, :string
    add_column :transactions, :enrichment_logo, :string
    add_column :transactions, :enrichment_mcc, :integer
    add_column :transactions, :enrichment_merchant_name, :string
    add_column :transactions, :enrichment_merchant_id, :string
    add_column :transactions, :enrichment_merchant_website, :string
    add_column :transactions, :enrichment_person, :string
    add_column :transactions, :enrichment_recurrence, :string
    add_column :transactions, :enrichment_recurrence_group, :jsonb, default: {}
  end
end
