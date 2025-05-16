class RemoveStockExchanges < ActiveRecord::Migration[7.2]
  def change
    drop_table :stock_exchanges do |t|
      t.string :name, null: false
      t.string :acronym
      t.string :mic, null: false
      t.string :country, null: false
      t.string :country_code, null: false
    end
  end
end
