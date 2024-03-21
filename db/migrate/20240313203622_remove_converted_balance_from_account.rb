class RemoveConvertedBalanceFromAccount < ActiveRecord::Migration[7.2]
  def change
    remove_column :accounts, :converted_balance, :decimal
    remove_column :accounts, :converted_currency, :string
  end
end
