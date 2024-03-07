class CreateTransactionCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :transaction_categories, id: :uuid do |t|
      t.string "name", null: false
      t.string "color", default: "#6172F3", null: false
      t.string "internal_category"
      t.references :family, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_reference :transactions, :category, foreign_key: { to_table: :transaction_categories }, type: :uuid
  end
end
