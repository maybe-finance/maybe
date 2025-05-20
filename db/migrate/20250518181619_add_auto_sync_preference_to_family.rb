class AddAutoSyncPreferenceToFamily < ActiveRecord::Migration[7.2]
  def change
    add_column :families, :auto_sync_on_login, :boolean, default: true, null: false
  end
end
