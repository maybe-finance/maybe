class AddBalanceComponents < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :cash_balance, :decimal, precision: 19, scale: 4, default: 0
    add_column :account_balances, :cash_balance, :decimal, precision: 19, scale: 4, default: 0
  end
end
