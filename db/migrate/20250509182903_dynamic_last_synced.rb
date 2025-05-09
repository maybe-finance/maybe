class DynamicLastSynced < ActiveRecord::Migration[7.2]
  def change
    remove_column :plaid_items, :last_synced_at, :datetime
    remove_column :accounts, :last_synced_at, :datetime
    remove_column :families, :last_synced_at, :datetime
  end
end
