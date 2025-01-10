class CategoryClassification < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :classification, :string, null: false, default: "expense"
    add_column :categories, :lucide_icon, :string
  end
end
