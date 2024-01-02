class AddLastSyncedAtToSecurities < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :last_synced_at, :datetime
  end
end
