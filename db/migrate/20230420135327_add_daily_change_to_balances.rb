class AddDailyChangeToBalances < ActiveRecord::Migration[7.1]
  def change
    add_column :balances, :change, :decimal, precision: 23, scale: 8, default: 0
  end
end
