class CreateBudgets < ActiveRecord::Migration[7.2]
  def change
    create_table :budgets, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :budgeted_amount, null: false, precision: 19, scale: 4
      t.decimal :expected_income, null: false, precision: 19, scale: 4

      t.timestamps
    end
  end
end
