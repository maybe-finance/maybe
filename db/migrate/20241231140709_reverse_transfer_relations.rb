class ReverseTransferRelations < ActiveRecord::Migration[7.2]
  def change
    create_table :transfers, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.references :inflow_transaction, null: false, foreign_key: { to_table: :account_transactions }, type: :uuid
      t.references :outflow_transaction, null: false, foreign_key: { to_table: :account_transactions }, type: :uuid
      t.string :status, null: false, default: "pending"
      t.text :notes

      t.index [ :inflow_transaction_id, :outflow_transaction_id ], unique: true
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO transfers (inflow_transaction_id, outflow_transaction_id, status, created_at, updated_at)
          SELECT
            CASE WHEN e1.amount <= 0 THEN e1.entryable_id ELSE e2.entryable_id END as inflow_transaction_id,
            CASE WHEN e1.amount <= 0 THEN e2.entryable_id ELSE e1.entryable_id END as outflow_transaction_id,
            'confirmed' as status,
            e1.created_at,
            e1.updated_at
          FROM account_entries e1
          JOIN account_entries e2 ON
            e1.transfer_id = e2.transfer_id AND
            e1.id != e2.id AND
            e1.id < e2.id -- Ensures we don't duplicate transfers from both sides
          JOIN accounts a1 ON e1.account_id = a1.id
          JOIN accounts a2 ON e2.account_id = a2.id
          WHERE
            e1.entryable_type = 'Account::Transaction' AND
            e2.entryable_type = 'Account::Transaction' AND
            e1.transfer_id IS NOT NULL AND
            a1.family_id = a2.family_id;
        SQL
      end

      dir.down do
        execute <<~SQL
          WITH new_transfers AS (
            INSERT INTO account_transfers (created_at, updated_at)
            SELECT created_at, updated_at
            FROM transfers
            RETURNING id, created_at
          ),
          transfer_pairs AS (
            SELECT
              nt.id as transfer_id,
              ae_in.id as inflow_entry_id,
              ae_out.id as outflow_entry_id
            FROM transfers t
            JOIN new_transfers nt ON nt.created_at = t.created_at
            JOIN account_entries ae_in ON ae_in.entryable_id = t.inflow_transaction_id
            JOIN account_entries ae_out ON ae_out.entryable_id = t.outflow_transaction_id
            WHERE
              ae_in.entryable_type = 'Account::Transaction' AND
              ae_out.entryable_type = 'Account::Transaction'
          )
          UPDATE account_entries ae
          SET transfer_id = tp.transfer_id
          FROM transfer_pairs tp
          WHERE ae.id IN (tp.inflow_entry_id, tp.outflow_entry_id);
        SQL
      end
    end

    remove_foreign_key :account_entries, :account_transfers, column: :transfer_id
    remove_column :account_entries, :transfer_id, :uuid
    remove_column :account_entries, :marked_as_transfer, :boolean

    drop_table :account_transfers, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.timestamps
    end
  end
end
