class RenameCategoriesTable < ActiveRecord::Migration[7.2]
  def change
    rename_table :transaction_categories, :categories
  end
end
