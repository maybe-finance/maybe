class AddStartBalanceToAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :start_balance, :decimal, precision: 19, scale: 4
  end
end
