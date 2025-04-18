class RemoveGoodJob < ActiveRecord::Migration[7.2]
  def up
    drop_table :good_job_batches
    drop_table :good_job_executions
    drop_table :good_job_processes
    drop_table :good_job_settings
    drop_table :good_jobs
  end

  def down
    # Add the tables back if needed - see schema.rb for the full table definitions
    raise ActiveRecord::IrreversibleMigration
  end
end
