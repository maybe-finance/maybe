class AddUniqueIndicesToTransfers < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :transfers, :inflow_transaction_id, unique: true, algorithm: :concurrently
    add_index :transfers, :outflow_transaction_id, unique: true, algorithm: :concurrently
  end
end
