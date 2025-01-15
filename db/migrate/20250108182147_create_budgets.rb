class CreateBudgets < ActiveRecord::Migration[7.2]
  def change
    create_table :budgets, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :budgeted_spending, precision: 19, scale: 4
      t.decimal :expected_income, precision: 19, scale: 4
      t.string :currency, null: false
      t.timestamps
    end

    add_index :budgets, %i[family_id start_date end_date], unique: true
  end
end
