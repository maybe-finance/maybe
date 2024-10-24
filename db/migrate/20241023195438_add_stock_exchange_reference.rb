class AddStockExchangeReference < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :country_code, :string
    add_reference :securities, :stock_exchange, type: :uuid, foreign_key: true
    add_index :securities, :country_code
  end
end
