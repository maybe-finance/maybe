class FixUserRoleColumnType < ActiveRecord::Migration[7.2]
  def change
    # First remove any constraints/references to the enum
    execute <<-SQL
      ALTER TABLE users ALTER COLUMN role TYPE varchar USING role::text;
    SQL

    # Then set the default
    change_column_default :users, :role, 'member'

    # Finally drop the enum type
    execute <<-SQL
      DROP TYPE IF EXISTS user_role;
    SQL
  end
end
