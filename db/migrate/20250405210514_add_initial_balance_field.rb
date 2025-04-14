class AddInitialBalanceField < ActiveRecord::Migration[7.2]
  def change
    add_column :loans, :initial_balance, :decimal, precision: 19, scale: 4
  end
end
