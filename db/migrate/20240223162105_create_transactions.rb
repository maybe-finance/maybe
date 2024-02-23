class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions, id: :uuid do |t|
      t.string :name
      t.date :date, null: false
      t.decimal :amount, precision: 19, scale: 4, null: false
      t.string :currency, default: "USD", null: false
      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
