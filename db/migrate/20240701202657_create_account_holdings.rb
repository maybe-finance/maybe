class CreateAccountHoldings < ActiveRecord::Migration[7.2]
  def change
    create_table :account_holdings, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :security, null: false, foreign_key: true, type: :uuid
      t.date :date, null: false
      t.decimal :qty, precision: 19, scale: 4
      t.decimal :amount, precision: 19, scale: 4
      t.string :currency

      t.timestamps
    end
  end
end
