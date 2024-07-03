class AddBalanceComponentsToBalanceTable < ActiveRecord::Migration[7.2]
  def change
    add_column :account_balances, :holdings_balance, :decimal, precision: 19, scale: 4
    add_column :account_balances, :cash_balance, :decimal, precision: 19, scale: 4
  end
end
