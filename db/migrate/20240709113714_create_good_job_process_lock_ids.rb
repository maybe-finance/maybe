# frozen_string_literal: true

class CreateGoodJobProcessLockIds < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.column_exists?(:good_jobs, :locked_by_id)
      end
    end

    add_column :good_jobs, :locked_by_id, :uuid
    add_column :good_jobs, :locked_at, :datetime
    add_column :good_job_executions, :process_id, :uuid
    add_column :good_job_processes, :lock_type, :integer, limit: 2
  end
end
