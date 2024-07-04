class RemoveAccountSyncFields < ActiveRecord::Migration[7.2]
  def change
    remove_column :accounts, :last_sync_date, :date
    remove_column :accounts, :sync_warnings, :jsonb
    remove_column :accounts, :sync_errors, :jsonb
    remove_column :accounts, :status, :enum, enum_type: :account_status
    drop_enum :account_status, %w[ok syncing error]
  end
end
