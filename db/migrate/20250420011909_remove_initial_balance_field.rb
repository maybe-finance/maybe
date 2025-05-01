class RemoveInitialBalanceField < ActiveRecord::Migration[7.2]
  def change
    remove_column :loans, :initial_balance, :decimal
  end
end
