class RenameAccountBalance < ActiveRecord::Migration[7.2]
  def change
    rename_column :accounts, :original_balance, :balance
    rename_column :accounts, :original_currency, :currency
  end
end
