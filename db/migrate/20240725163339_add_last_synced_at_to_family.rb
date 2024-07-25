class AddLastSyncedAtToFamily < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :last_synced_at, :datetime
  end
end
