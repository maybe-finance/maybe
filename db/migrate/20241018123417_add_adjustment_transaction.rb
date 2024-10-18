class AddAdjustmentTransaction < ActiveRecord::Migration[7.2]
  def change
    add_column :account_transactions, :adjustment, :boolean, default: false
    add_column :accounts, :user_provided_start_balance, :decimal, precision: 19, scale: 4
  end
end
