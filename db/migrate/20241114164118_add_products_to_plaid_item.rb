class AddProductsToPlaidItem < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :available_products, :string, array: true, default: []
    add_column :plaid_items, :billed_products, :string, array: true, default: []

    rename_column :families, :last_auto_synced_at, :last_synced_at
    add_column :plaid_items, :last_synced_at, :datetime
    add_column :accounts, :last_synced_at, :datetime
  end
end
