class FixImportsSchemaDuplicates < ActiveRecord::Migration[7.2]
  def up
    # First, ensure any existing number_format values are using the default format
    execute <<-SQL
      UPDATE imports#{' '}
      SET number_format = '1,234.56'#{' '}
      WHERE number_format IS NULL OR number_format = '';
    SQL

    # Remove the duplicate number_format column (if it exists) and add it back with the default
    change_table :imports do |t|
      t.remove :number_format if column_exists?(:imports, :number_format)
      t.string :number_format, default: '1,234.56'
    end

    # Remove the stale currency column if it exists
    remove_column :imports, :currency if column_exists?(:imports, :currency)
  end

  def down
    # No need to restore the duplicate column or stale currency field
    raise ActiveRecord::IrreversibleMigration
  end
end
