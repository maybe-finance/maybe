class AddMarkedForDeletionToUser < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :marked_for_deletion, :boolean, default: false, null: false
  end
end
