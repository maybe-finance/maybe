class AddBalanceComponentsToInvestmentAccounts < ActiveRecord::Migration[7.2]
  def change
    add_column :investments, :cash_balance, :decimal, precision: 19, scale: 4
    add_column :investments, :holdings_balance, :decimal, precision: 19, scale: 4
  end
end
