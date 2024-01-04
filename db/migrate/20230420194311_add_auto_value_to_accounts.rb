class AddAutoValueToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :auto_valuation, :boolean, default: false
  end
end
