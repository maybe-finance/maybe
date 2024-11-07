class AddPlaidDomain < ActiveRecord::Migration[7.2]
  def change
    create_table :plaid_items, id: :uuid do |t|
      t.references :family, null: false, type: :uuid, foreign_key: true
      t.string :access_token
      t.string :plaid_id
      t.string :name
      t.datetime :last_synced_at
      t.timestamps
    end

    create_table :plaid_accounts, id: :uuid do |t|
      t.references :plaid_item, null: false, type: :uuid, foreign_key: true
      t.string :plaid_id

      t.timestamps
    end

    add_reference :accounts, :plaid_account, type: :uuid, foreign_key: true

    remove_reference :accounts, :institution
    drop_table :institutions do |t|
      t.timestamps
    end
  end
end
