class IncomeCategory < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :classification, :string, null: false, default: "expense"

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE categories
          SET classification = 'income'
          WHERE LOWER(name) = 'income'
        SQL

        # Assign the transfer classification for any entries marked as transfer
        execute <<-SQL
          UPDATE categories
          SET classification = 'transfer'
          WHERE id IN (
            SELECT DISTINCT t.category_id
            FROM account_entries e
            INNER JOIN account_transactions t ON t.id = e.entryable_id AND e.entryable_type = 'Account::Transaction'
            WHERE e.marked_as_transfer = true AND t.category_id IS NOT NULL
          )
        SQL

        # We will now use categories to identify one-way transfers, and Account::Transfer for two-way transfers
        remove_column :account_entries, :marked_as_transfer
      end

      dir.down do
        add_column :account_entries, :marked_as_transfer, :boolean, null: false, default: false
      end
    end
  end
end
