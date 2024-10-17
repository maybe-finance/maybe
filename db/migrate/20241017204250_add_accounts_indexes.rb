class AddAccountsIndexes < ActiveRecord::Migration[7.2]
  def change
    add_index :accounts, [ :family_id, :accountable_type ]
    add_index :accounts, [ :accountable_id, :accountable_type ]
    add_index :accounts, [ :family_id, :id ]
  end
end
