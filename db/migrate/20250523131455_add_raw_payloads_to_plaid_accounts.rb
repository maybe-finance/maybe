class AddRawPayloadsToPlaidAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :raw_payload, :jsonb, default: {}
    add_column :plaid_items, :raw_institution_payload, :jsonb, default: {}

    change_column_null :plaid_items, :plaid_id, false
    add_index :plaid_items, :plaid_id, unique: true

    add_column :plaid_accounts, :raw_payload, :jsonb, default: {}
    add_column :plaid_accounts, :raw_transactions_payload, :jsonb, default: {}
    add_column :plaid_accounts, :raw_investments_payload, :jsonb, default: {}
    add_column :plaid_accounts, :raw_liabilities_payload, :jsonb, default: {}

    change_column_null :plaid_accounts, :plaid_id, false
    change_column_null :plaid_accounts, :plaid_type, false
    change_column_null :plaid_accounts, :currency, false
    change_column_null :plaid_accounts, :name, false
    add_index :plaid_accounts, :plaid_id, unique: true

    # No longer need to store on transaction model because it is stored in raw_transactions_payload
    remove_column :transactions, :plaid_category, :string
    remove_column :transactions, :plaid_category_detailed, :string
  end
end
