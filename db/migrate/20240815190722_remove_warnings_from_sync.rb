class RemoveWarningsFromSync < ActiveRecord::Migration[7.2]
  def change
    remove_column :account_syncs, :warnings, :text, array: true, default: []
  end
end
