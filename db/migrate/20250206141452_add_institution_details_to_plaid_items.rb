class AddInstitutionDetailsToPlaidItems < ActiveRecord::Migration[7.2]
  def change
    add_column :plaid_items, :institution_url, :string
    add_column :plaid_items, :institution_id, :string
    add_column :plaid_items, :institution_color, :string
  end
end
