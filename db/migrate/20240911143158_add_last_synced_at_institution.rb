class AddLastSyncedAtInstitution < ActiveRecord::Migration[7.2]
  def change
    add_column :institutions, :last_synced_at, :datetime
  end
end
