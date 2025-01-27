class CreateRejectedTransfers < ActiveRecord::Migration[7.2]
  def change
    create_table :rejected_transfers, id: :uuid do |t|
      t.references :inflow_transaction, null: false, foreign_key: { to_table: :account_transactions }, type: :uuid
      t.references :outflow_transaction, null: false, foreign_key: { to_table: :account_transactions }, type: :uuid
      t.timestamps
    end

    add_index :rejected_transfers, [ :inflow_transaction_id, :outflow_transaction_id ], unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO rejected_transfers (inflow_transaction_id, outflow_transaction_id, created_at, updated_at)
          SELECT
            inflow_transaction_id,
            outflow_transaction_id,
            created_at,
            updated_at
          FROM transfers
          WHERE status = 'rejected'
        SQL

        execute <<~SQL
          DELETE FROM transfers
          WHERE status = 'rejected'
        SQL
      end

      dir.down do
        execute <<~SQL
          INSERT INTO transfers (inflow_transaction_id, outflow_transaction_id, status, created_at, updated_at)
          SELECT
            inflow_transaction_id,
            outflow_transaction_id,
            'rejected',
            created_at,
            updated_at
          FROM rejected_transfers
        SQL
      end
    end
  end
end
