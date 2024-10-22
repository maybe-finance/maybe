class CreateStockExchanges < ActiveRecord::Migration[7.2]
  def change
    create_table :stock_exchanges, id: :uuid do |t|
      t.string :name, null: false
      t.string :acronym
      t.string :mic, null: false
      t.string :country, null: false
      t.string :country_code, null: false
      t.string :city, null: false
      t.string :website
      t.string :timezone_name, null: false
      t.string :timezone_abbr, null: false
      t.string :timezone_abbr_dst
      t.string :currency_code, null: false
      t.string :currency_symbol, null: false
      t.string :currency_name, null: false
      t.timestamps
    end

    add_index :stock_exchanges, :country
    add_index :stock_exchanges, :country_code
    add_index :stock_exchanges, :currency_code
  end
end
