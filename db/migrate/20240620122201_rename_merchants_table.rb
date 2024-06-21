class RenameMerchantsTable < ActiveRecord::Migration[7.2]
  def change
    rename_table :transaction_merchants, :merchants
  end
end
