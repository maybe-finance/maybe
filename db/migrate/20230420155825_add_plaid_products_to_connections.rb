class AddPlaidProductsToConnections < ActiveRecord::Migration[7.1]
  def change
    add_column :connections, :plaid_products, :string, array: true, default: []
  end
end
