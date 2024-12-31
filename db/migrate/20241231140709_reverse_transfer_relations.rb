class ReverseTransferRelations < ActiveRecord::Migration[7.2]
  def change
    create_table :transfers, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.references :inflow_transaction, null: false, foreign_key: { to_table: :account_transactions }, type: :uuid
      t.references :outflow_transaction, null: false, foreign_key: { to_table: :account_transactions }, type: :uuid
      t.string :status, null: false, default: "pending"

      t.index [:inflow_transaction_id, :outflow_transaction_id], unique: true
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO transfers (inflow_transaction_id, outflow_transaction_id, status, created_at, updated_at)
          SELECT
            e_in.entryable_id as inflow_transaction_id,
            e_out.entryable_id as outflow_transaction_id,
            'confirmed' as status,
            e_in.created_at,
            e_in.updated_at
          FROM account_entries e_in
          JOIN account_entries e_out ON 
            e_in.transfer_id = e_out.transfer_id AND 
            e_in.id != e_out.id AND
            e_in.id < e_out.id -- Ensures we don't duplicate transfers from both sides
          JOIN accounts a_in ON e_in.account_id = a_in.id
          JOIN accounts a_out ON e_out.account_id = a_out.id
          WHERE
            e_in.entryable_type = 'Account::Transaction' AND 
            e_out.entryable_type = 'Account::Transaction' AND
            e_in.transfer_id IS NOT NULL AND 
            a_in.family_id = a_out.family_id; -- extra safeguard, not 100% necessary
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
