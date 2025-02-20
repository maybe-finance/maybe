class AddDefaultLucideIconToCategories < ActiveRecord::Migration[7.2]
  def change
    change_column_null :categories, :lucide_icon, false
    change_column_default :categories, :lucide_icon, 'shapes'
  end
end
