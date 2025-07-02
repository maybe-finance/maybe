class AddAccountStatus < ActiveRecord::Migration[7.2]
  def up
    add_column :accounts, :status, :string, default: "active"

    # Migrate existing data
    execute <<-SQL
      UPDATE accounts
      SET status = CASE
        WHEN scheduled_for_deletion = true THEN 'pending_deletion'
        WHEN is_active = true THEN 'active'
        WHEN is_active = false THEN 'disabled'
        ELSE 'draft'
      END
    SQL
  end

  def down
    # Restore the original boolean fields based on status
    execute <<-SQL
      UPDATE accounts
      SET is_active = CASE
        WHEN status = 'active' THEN true
        WHEN status IN ('disabled', 'pending_deletion') THEN false
        ELSE false
      END,
      scheduled_for_deletion = CASE
        WHEN status = 'pending_deletion' THEN true
        ELSE false
      END
    SQL

    remove_column :accounts, :status
  end
end
