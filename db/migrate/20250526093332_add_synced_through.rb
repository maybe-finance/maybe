class AddSyncedThrough < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :data_synced_through, :date
    add_column :plaid_items, :data_synced_through, :date
    add_column :accounts, :data_synced_through, :date
  end
end
