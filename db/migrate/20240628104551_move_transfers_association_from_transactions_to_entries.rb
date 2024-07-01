class MoveTransfersAssociationFromTransactionsToEntries < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        add_reference :account_entries, :transfer, foreign_key: { to_table: :account_transfers }, type: :uuid
        add_column :account_entries, :marked_as_transfer, :boolean, default: false, null: false

        execute <<-SQL.squish
          UPDATE account_entries
          SET transfer_id = transactions.transfer_id,
              marked_as_transfer = transactions.marked_as_transfer
          FROM account_transactions AS transactions
          WHERE account_entries.entryable_id = transactions.id
          AND account_entries.entryable_type = 'Account::Transaction'
        SQL

        remove_reference :account_transactions, :transfer, foreign_key: { to_table: :account_transfers }, type: :uuid
        remove_column :account_transactions, :marked_as_transfer
      end

      dir.down do
        add_reference :account_transactions, :transfer, foreign_key: { to_table: :account_transfers }, type: :uuid
        add_column :account_transactions, :marked_as_transfer, :boolean, default: false, null: false

        execute <<-SQL.squish
          UPDATE account_transactions
          SET transfer_id = account_entries.transfer_id,
              marked_as_transfer = account_entries.marked_as_transfer
          FROM account_entries
          WHERE account_entries.entryable_id = account_transactions.id
          AND account_entries.entryable_type = 'Account::Transaction'
        SQL

        remove_reference :account_entries, :transfer, foreign_key: { to_table: :account_transfers }, type: :uuid
        remove_column :account_entries, :marked_as_transfer
      end
    end
  end
end
