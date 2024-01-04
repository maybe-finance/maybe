class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.string :name
      t.decimal :amount, precision: 19, scale: 2
      t.boolean :is_pending, default: false
      t.date :date
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.string :currency_code
      t.string :source_transaction_id
      t.string :source_category_id
      t.string :source_type
      t.jsonb :categories
      t.string :merchant_name
      t.integer :flow, default: 0
      t.boolean :excluded, default: false
      t.string :payment_channel
      t.jsonb :enrichment, default: {}
      t.datetime :enriched_at

      t.timestamps
    end
  end
end
