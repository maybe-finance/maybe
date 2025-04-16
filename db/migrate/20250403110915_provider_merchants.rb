class ProviderMerchants < ActiveRecord::Migration[7.2]
  def change
    change_column_null :merchants, :family_id, true
    change_column_null :merchants, :color, true
    change_column_default :merchants, :color, from: "#e99537", to: nil
    remove_column :merchants, :enriched_at, :datetime
    rename_column :merchants, :icon_url, :logo_url

    add_column :merchants, :website_url, :string
    add_column :merchants, :type, :string
    add_index :merchants, :type

    reversible do |dir|
      dir.up do
        # All of our existing merchants are family-generated right now
        Merchant.update_all(type: "FamilyMerchant")
      end
    end

    change_column_null :merchants, :type, false

    # Provider specific columns
    add_column :merchants, :source, :string
    add_column :merchants, :provider_merchant_id, :string

    add_index :merchants, [ :family_id, :name ], unique: true, where: "type = 'FamilyMerchant'"
    add_index :merchants, [ :source, :name, :website_url ], unique: true, where: "type = 'ProviderMerchant'"
  end
end
