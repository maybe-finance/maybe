class MigrateEntryables < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        # Migrate Account::Transaction data
        execute <<-SQL.squish
          INSERT INTO account_entries (name, date, amount, currency, account_id, entryable_type, entryable_id, created_at, updated_at)
          SELECT name, date, amount, currency, account_id, 'Account::Transaction', id, created_at, updated_at
          FROM account_transactions
        SQL

        # Migrate Account::Valuation data
        execute <<-SQL.squish
          INSERT INTO account_entries (name, date, amount, currency, account_id, entryable_type, entryable_id, created_at, updated_at)
          SELECT 'Manual valuation', date, value, currency, account_id, 'Account::Valuation', id, created_at, updated_at
          FROM account_valuations
        SQL
      end

      dir.down do
        # Delete the entries from account_entries
        execute <<-SQL.squish
          DELETE FROM account_entries WHERE entryable_type IN ('Account::Transaction', 'Account::Valuation')
        SQL
      end
    end
  end
end
