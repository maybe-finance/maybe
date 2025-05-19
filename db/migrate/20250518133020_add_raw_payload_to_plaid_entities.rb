class AddRawPayloadToPlaidEntities < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :raw_payload, :jsonb, default: {}
    add_column :plaid_items, :raw_institution_payload, :jsonb, default: {}

    add_column :plaid_accounts, :raw_payload, :jsonb, default: {}
    add_column :plaid_accounts, :raw_transactions_payload, :jsonb, default: {}
    add_column :plaid_accounts, :raw_investments_payload, :jsonb, default: {}
    add_column :plaid_accounts, :raw_liabilities_payload, :jsonb, default: {}
  end
end
