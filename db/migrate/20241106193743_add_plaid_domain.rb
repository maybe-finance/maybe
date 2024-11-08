class AddPlaidDomain < ActiveRecord::Migration[7.2]
  def change
    create_table :plaid_items, id: :uuid do |t|
      t.references :family, null: false, type: :uuid, foreign_key: true
      t.string :access_token
      t.string :plaid_id
      t.string :name
      t.timestamps
    end

    create_table :plaid_accounts, id: :uuid do |t|
      t.references :plaid_item, null: false, type: :uuid, foreign_key: true
      t.string :plaid_id
      t.string :plaid_type
      t.string :plaid_subtype
      t.decimal :current_balance, precision: 19, scale: 4
      t.decimal :available_balance, precision: 19, scale: 4
      t.string :currency
      t.string :name
      t.string :mask

      t.timestamps
    end

    create_table :syncs, id: :uuid do |t|
      t.references :syncable, polymorphic: true, null: false, type: :uuid
      t.references :parent_sync, type: :uuid
      t.datetime :last_ran_at
      t.date :start_date
      t.string :status, default: "pending"
      t.string :error
      t.jsonb :data

      t.timestamps
    end

    remove_column :families, :last_synced_at, :datetime
    remove_column :accounts, :last_sync_date, :date
    remove_reference :accounts, :institution
    add_reference :accounts, :plaid_account, type: :uuid, foreign_key: true

    drop_table :account_syncs do |t|
      t.timestamps
    end

    drop_table :institutions do |t|
      t.timestamps
    end
  end
end
