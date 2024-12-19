class AddParentCategory < ActiveRecord::Migration[7.2]
  def change
    add_column :categories, :parent_category_id, :uuid
  end
end
