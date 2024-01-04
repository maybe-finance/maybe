class AddPropertyDetailsToAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :property_details, :jsonb, default: {}
  end
end
