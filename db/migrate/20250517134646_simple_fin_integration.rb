class SimpleFinIntegration < ActiveRecord::Migration[7.2]
  def change
    create_table :simple_fin_items, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.string :institution_id # From SimpleFIN org.id (e.g., "www.chase.com")
      t.string :institution_name
      t.string :institution_url
      t.string :institution_domain
      t.string :status, default: "good" # e.g., good, requires_update
      t.string :institution_errors, array: true, default: []
      t.boolean :scheduled_for_deletion, default: false

      t.timestamps
    end

    create_table :simple_fin_accounts do |t|
      t.references :simple_fin_item, null: false, foreign_key: true, type: :uuid
      t.string :external_id, null: false
      t.decimal :current_balance, precision: 19, scale: 4
      t.decimal :available_balance, precision: 19, scale: 4
      t.string :currency

      t.timestamps
    end
    add_index :simple_fin_accounts, [ :simple_fin_item_id, :external_id ], unique: true, name: 'index_sfa_on_sfc_id_and_external_id'

    add_reference :accounts, :simple_fin_account, foreign_key: true, null: true, index: true

    add_column :entries, :simple_fin_transaction_id, :string
    add_index :entries, :simple_fin_transaction_id, unique: true, where: "simple_fin_transaction_id IS NOT NULL"
    add_column :entries, :source, :string
    add_column :transactions, :simple_fin_category, :string

    add_column :holdings, :simple_fin_holding_id, :string
    add_index :holdings, :simple_fin_holding_id, unique: true, where: "simple_fin_holding_id IS NOT NULL"
    add_column :holdings, :source, :string

    create_table :simple_fin_rate_limits, id: :uuid do |t|
      t.date :date, null: false
      t.integer :call_count, null: false, default: 0

      t.timestamps
    end
    add_index :simple_fin_rate_limits, [ :date ], unique: true, name: 'index_sfrl_on_date'
  end
end
