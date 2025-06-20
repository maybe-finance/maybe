class UpdateExcludedTransactionsToOneTime < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        # Update all transactions that have excluded entries to be one_time
        # They remain excluded as well since users were using excluded as "one time" before
        execute <<~SQL
          UPDATE transactions
          SET kind = 'one_time'
          FROM entries
          WHERE entries.entryable_id = transactions.id
            AND entries.entryable_type = 'Transaction'
            AND entries.excluded = true
            AND transactions.kind = 'standard'
        SQL
      end

      dir.down do
        # Revert one_time transactions back to standard if their entry is excluded
        # This assumes these were the ones we migrated in the up method
        execute <<~SQL
          UPDATE transactions
          SET kind = 'standard'
          FROM entries
          WHERE entries.entryable_id = transactions.id
            AND entries.entryable_type = 'Transaction'
            AND entries.excluded = true
            AND transactions.kind = 'one_time'
        SQL
      end
    end
  end
end
