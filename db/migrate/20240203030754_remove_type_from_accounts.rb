class RemoveTypeFromAccounts < ActiveRecord::Migration[7.2]
  def change
    remove_column :accounts, :type
  end
end
