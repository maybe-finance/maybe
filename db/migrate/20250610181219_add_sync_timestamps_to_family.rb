class AddSyncTimestampsToFamily < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :latest_sync_activity_at, :datetime, default: -> { "CURRENT_TIMESTAMP" }
    add_column :families, :latest_sync_completed_at, :datetime, default: -> { "CURRENT_TIMESTAMP" }
  end
end
