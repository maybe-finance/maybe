class AddPlaidItem < ActiveRecord::Migration[7.2]
  def change
    create_table :plaid_items, id: :uuid do |t|
      t.references :family, null: false, type: :uuid, foreign_key: true
      t.string :plaid_access_token_digest
      t.string :plaid_id
      t.timestamps
    end

    create_table :plaid_accounts, id: :uuid do |t|
      t.references :plaid_item, null: false, type: :uuid, foreign_key: true
      t.references :account, null: false, type: :uuid, foreign_key: true
      t.string :plaid_id

      t.timestamps
    end
  end
end
