class UpdateSyncTimestamps < ActiveRecord::Migration[7.2]
  def change
    # Timestamps, managed by aasm
    add_column :syncs, :pending_at, :datetime
    add_column :syncs, :syncing_at, :datetime
    add_column :syncs, :completed_at, :datetime
    add_column :syncs, :failed_at, :datetime

    add_column :syncs, :window_start_date, :date
    add_column :syncs, :window_end_date, :date

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE syncs
          SET
            completed_at = CASE
              WHEN status = 'completed' THEN last_ran_at
              ELSE NULL
            END,
            failed_at = CASE
              WHEN status = 'failed' THEN last_ran_at
              ELSE NULL
            END
        SQL

        execute <<-SQL
          UPDATE syncs
          SET window_start_date = start_date
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE syncs
          SET
            last_ran_at = completed_at
        SQL

        execute <<-SQL
          UPDATE syncs
          SET start_date = window_start_date
        SQL
      end
    end

    remove_column :syncs, :start_date, :date
    remove_column :syncs, :last_ran_at, :datetime
    remove_column :syncs, :error_backtrace, :text, array: true
  end
end
