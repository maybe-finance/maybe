class AddRegionToPlaidItem < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :plaid_region, :string, null: false, default: "us"
  end
end
