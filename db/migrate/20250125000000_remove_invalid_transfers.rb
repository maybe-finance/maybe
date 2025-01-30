class RemoveInvalidTransfers < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    # Remove transfers where a transaction is used in multiple transfers
    execute <<~SQL
      WITH duplicate_transfers AS (
        SELECT t.id
        FROM transfers t
        WHERE EXISTS (
          SELECT 1
          FROM transfers t2
          WHERE t2.id < t.id
          AND (
            t2.inflow_transaction_id = t.inflow_transaction_id
            OR t2.inflow_transaction_id = t.outflow_transaction_id
            OR t2.outflow_transaction_id = t.inflow_transaction_id
            OR t2.outflow_transaction_id = t.outflow_transaction_id
          )
        )
      )
      DELETE FROM transfers
      WHERE id IN (SELECT id FROM duplicate_transfers);
    SQL
  end

  def down
    # No rollback necessary as we can't restore deleted data
  end
end
