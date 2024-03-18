class ReplaceMoneyField < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :balance_cents, :integer
    change_column :accounts, :balance_cents, :integer, limit: 8
    remove_column :accounts, :balance
  end
end
