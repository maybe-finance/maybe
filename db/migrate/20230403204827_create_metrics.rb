class CreateMetrics < ActiveRecord::Migration[7.1]
  def change
    create_table :metrics, id: :uuid do |t|
      t.string :kind, null: false
      t.decimal :amount, precision: 19, scale: 2
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.date :date, null: false

      t.timestamps
    end
  end
end
