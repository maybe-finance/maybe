class AddSecurityDateIndexToSecurityPrices < ActiveRecord::Migration[7.2]
  def change
    add_index :security_prices, [:security_id, :date], unique: true
  end
end
