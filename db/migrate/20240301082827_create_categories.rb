class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_enum :category_type, [ "income", "expense" ]

    create_table :categories, id: :uuid do |t|
      t.string "name", null: false
      t.string "icon" # TODO: Icon might be turned into an enum of available icons
      t.string "color", null: false
      t.enum "category_type", enum_type: "category_type", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.boolean "is_default", default: false, null: false  # Default categories cannot be deleted by the user
      t.references :family, null: false, foreign_key: true, type: :uuid
    end

    add_reference :transactions, :category, null: false, foreign_key: true, type: :uuid
  end
end
