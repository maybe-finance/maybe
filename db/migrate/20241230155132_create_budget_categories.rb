class CreateBudgetCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :budget_categories, id: :uuid do |t|
      t.references :budget, null: false, foreign_key: true, type: :uuid
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.decimal :budgeted_amount, null: false, precision: 19, scale: 4

      t.timestamps
    end
  end
end
