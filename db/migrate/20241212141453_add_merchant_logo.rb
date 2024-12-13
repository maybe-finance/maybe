class AddMerchantLogo < ActiveRecord::Migration[7.2]
  def change
    add_column :merchants, :icon_url, :string
    add_column :merchants, :enriched_at, :datetime

    add_column :account_entries, :enriched_at, :datetime
  end
end
