class AddIndexToSyncStatus < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :syncs, :status, if_not_exists: true, algorithm: :concurrently
  end
end
