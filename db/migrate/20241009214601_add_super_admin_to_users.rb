class AddSuperAdminToUsers < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        change_column :users, :role, :string, default: 'member'

        execute <<-SQL
          DROP TYPE user_role;
        SQL
      end

      dir.down do
        execute <<-SQL
          CREATE TYPE user_role AS ENUM ('admin', 'member');
        SQL

        change_column_default :users, :role, nil
        change_column :users, :role, :user_role, using: 'role::user_role'
        change_column_default :users, :role, 'member'
      end
    end
  end
end
