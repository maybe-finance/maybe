class RedoMoneyStorage < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :original_balance, :decimal, precision: 19, scale: 4, default: 0.0
    add_column :accounts, :original_currency, :string, default: "USD"
    add_column :accounts, :converted_balance, :decimal, precision: 19, scale: 4, default: 0.0
    add_column :accounts, :converted_currency, :string, default: "USD"

    remove_column :accounts, :balance_cents
    remove_column :accounts, :currency
  end
end
