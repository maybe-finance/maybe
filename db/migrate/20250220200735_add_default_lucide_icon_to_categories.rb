class AddDefaultLucideIconToCategories < ActiveRecord::Migration[7.2]
  def up
    execute <<-SQL
      UPDATE categories
      SET lucide_icon = 'shapes'
      WHERE lucide_icon IS NULL
    SQL

    change_column_null :categories, :lucide_icon, false
    change_column_default :categories, :lucide_icon, 'shapes'
  end

  def down
    change_column_default :categories, :lucide_icon, nil
    change_column_null :categories, :lucide_icon, true

    execute <<-SQL
      UPDATE categories
      SET lucide_icon = NULL
      WHERE lucide_icon = 'shapes'
    SQL
  end
end
