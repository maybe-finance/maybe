class CreateAccountBalances < ActiveRecord::Migration[7.2]
  def change
    create_table :account_balances, id: :uuid do |t|
      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.date :date, null: false
      t.decimal :balance, precision: 19, scale: 4, null: false
      t.string :currency, default: "USD", null: false

      t.timestamps
    end

    add_index :account_balances, [ :account_id, :date ], unique: true
  end
end
