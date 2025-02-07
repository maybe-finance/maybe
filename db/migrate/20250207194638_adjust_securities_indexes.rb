class AdjustSecuritiesIndexes < ActiveRecord::Migration[7.2]
  def change
    remove_index :securities, name: "index_securities_on_ticker_and_exchange_mic"
    add_index :securities, [ :ticker, :exchange_operating_mic ], unique: true
  end
end
