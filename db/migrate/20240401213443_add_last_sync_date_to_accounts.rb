class AddLastSyncDateToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :last_sync_date, :date
  end
end
