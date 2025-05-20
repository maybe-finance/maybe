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

        # Due to some recent bugs, some self hosters have syncs that are stuck.
        # This manually fails those syncs so they stop seeing syncing UI notices.
        if Rails.application.config.app_mode.self_hosted?
          puts "Self hosted: Fail syncs older than 2 hours"
          execute <<-SQL
            UPDATE syncs
            SET status = 'failed'
            WHERE (
              status = 'syncing' AND
              created_at < NOW() - INTERVAL '2 hours'
            )
          SQL
        end
      end

      dir.down do
        execute <<-SQL
          UPDATE syncs
          SET
            last_ran_at = COALESCE(completed_at, failed_at)
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
