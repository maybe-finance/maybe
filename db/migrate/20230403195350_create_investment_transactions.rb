class CreateInvestmentTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :investment_transactions, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :security, null: false, foreign_key: true, type: :uuid
      t.date :date
      t.string :name
      t.decimal :amount, precision: 19, scale: 4
      t.decimal :quantity, precision: 36, scale: 18
      t.decimal :price, precision: 23, scale: 8
      t.string :currency_code
      t.string :source_transaction_id
      t.string :source_type
      t.string :source_subtype
      t.decimal :fees, precision: 19, scale: 4
      t.string :category

      t.timestamps
    end

    add_index :investment_transactions, :source_transaction_id, unique: true
  end
end
