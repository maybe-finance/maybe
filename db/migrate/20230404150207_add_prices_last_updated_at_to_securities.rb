class AddPricesLastUpdatedAtToSecurities < ActiveRecord::Migration[7.1]
  def change
    add_column :securities, :last_synced_at, :datetime, default: nil
  end
end
