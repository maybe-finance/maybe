class CreateValuations < ActiveRecord::Migration[7.2]
  def change
    create_table :valuations, id: :uuid do |t|
      t.string :type, null: false
      t.references :account, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.date :date, null: false
      t.decimal :value, precision: 19, scale: 4, null: false
      t.string :currency, default: "USD", null: false

      t.timestamps
    end

    # Since all dates are daily (no concept of time of day), limit account to 1 valuation per day
    add_index :valuations, [ :account_id, :date ], unique: true
  end
end
