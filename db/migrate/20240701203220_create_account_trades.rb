class CreateAccountTrades < ActiveRecord::Migration[7.2]
  def change
    create_table :account_trades, id: :uuid do |t|
      t.references :security, null: false, foreign_key: true, type: :uuid
      t.decimal :qty, precision: 19, scale: 4
      t.decimal :price, precision: 19, scale: 4

      t.timestamps
    end
  end
end
