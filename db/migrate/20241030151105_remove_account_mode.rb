class RemoveAccountMode < ActiveRecord::Migration[7.2]
  def change
    remove_column :accounts, :mode
  end
end
