class AddLimitToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :credit_limit, :decimal, precision: 10, scale: 2
  end
end
