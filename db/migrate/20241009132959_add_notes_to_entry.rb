class AddNotesToEntry < ActiveRecord::Migration[7.2]
  def change
    add_column :account_entries, :notes, :text
    add_column :account_entries, :excluded, :boolean, default: false

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE account_entries
          SET notes = account_transactions.notes,
              excluded = account_transactions.excluded
          FROM account_transactions
          WHERE account_entries.entryable_type = 'Account::Transaction'
            AND account_entries.entryable_id = account_transactions.id
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE account_transactions
          SET notes = account_entries.notes,
              excluded = account_entries.excluded
          FROM account_entries
          WHERE account_entries.entryable_type = 'Account::Transaction'
            AND account_entries.entryable_id = account_transactions.id
        SQL
      end
    end

    remove_column :account_transactions, :notes, :text
    remove_column :account_transactions, :excluded, :boolean
  end
end
