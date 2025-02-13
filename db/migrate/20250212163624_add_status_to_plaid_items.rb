class AddStatusToPlaidItems < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :status, :string, null: false, default: "good"
  end
end
