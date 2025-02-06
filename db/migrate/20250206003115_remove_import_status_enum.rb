class RemoveImportStatusEnum < ActiveRecord::Migration[7.2]
  def up
    change_column_default :imports, :status, nil
    change_column :imports, :status, :string
    execute "DROP TYPE IF EXISTS import_status"
  end

  def down
    execute <<-SQL
      CREATE TYPE import_status AS ENUM (
        'pending',
        'importing',
        'complete',
        'failed'
      );
    SQL

    change_column :imports, :status, :import_status, using: 'status::import_status'
    change_column_default :imports, :status, 'pending'
  end
end
