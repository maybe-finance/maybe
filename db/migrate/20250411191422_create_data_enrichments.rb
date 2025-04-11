class CreateDataEnrichments < ActiveRecord::Migration[7.2]
  def change
    create_table :data_enrichments, id: :uuid do |t|
      t.string :source

      t.timestamps
    end

    add_column :account_transactions, :locked_fields, :jsonb, default: {}
    add_column :account_entries, :locked_fields, :jsonb, default: {}
  end
end
