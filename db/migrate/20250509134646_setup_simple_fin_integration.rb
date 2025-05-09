class SetupSimpleFinIntegration < ActiveRecord::Migration[7.2]
  def change
    create_table :simple_fin_connections do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :institution_id
      t.string :institution_name
      t.string :institution_url
      t.string :institution_domain
      t.string :status, default: "good"
      t.datetime :last_synced_at
      t.boolean :scheduled_for_deletion, default: false
      t.string :api_versions_supported, array: true, default: []

      t.timestamps
    end

    create_table :simple_fin_accounts do |t|
      t.references :simple_fin_connection, null: false, foreign_key: true
      t.string :external_id, null: false
      t.decimal :current_balance, precision: 19, scale: 4
      t.decimal :available_balance, precision: 19, scale: 4
      t.string :currency
      t.string :sf_type
      t.string :sf_subtype

      t.timestamps
    end
    add_index :simple_fin_accounts, [ :simple_fin_connection_id, :external_id ], unique: true, name: 'index_sfa_on_sfc_id_and_external_id'

    add_reference :accounts, :simple_fin_account, foreign_key: true, null: true, index: true
  end
end
