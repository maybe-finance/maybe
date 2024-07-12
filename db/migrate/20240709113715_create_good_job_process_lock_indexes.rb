# frozen_string_literal: true

class CreateGoodJobProcessLockIndexes < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked)
          add_index :good_jobs, [ :priority, :scheduled_at ],
                    order: { priority: "ASC NULLS LAST", scheduled_at: :asc },
                    where: "finished_at IS NULL AND locked_by_id IS NULL",
                    name: :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked,
                    algorithm: :concurrently
        end

        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_locked_by_id)
          add_index :good_jobs, :locked_by_id,
                    where: "locked_by_id IS NOT NULL",
                    name: :index_good_jobs_on_locked_by_id,
                    algorithm: :concurrently
        end

        unless connection.index_name_exists?(:good_job_executions, :index_good_job_executions_on_process_id_and_created_at)
          add_index :good_job_executions, [ :process_id, :created_at ],
                    name: :index_good_job_executions_on_process_id_and_created_at,
                    algorithm: :concurrently
        end
      end

      dir.down do
        remove_index(:good_jobs, name: :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked) if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked)
        remove_index(:good_jobs, name: :index_good_jobs_on_locked_by_id) if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_locked_by_id)
        remove_index(:good_job_executions, name: :index_good_job_executions_on_process_id_and_created_at) if connection.index_name_exists?(:good_job_executions, :index_good_job_executions_on_process_id_and_created_at)
      end
    end
  end
end
