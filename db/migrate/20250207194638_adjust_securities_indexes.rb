class AdjustSecuritiesIndexes < ActiveRecord::Migration[7.2]
  def change
    # Add back the original index that was removed
    add_index :securities, [ :ticker, :exchange_mic ], unique: true, name: "index_securities_on_ticker_and_exchange_mic"

    # Add the new index for exchange_operating_mic
    add_index :securities, [ :ticker, :exchange_operating_mic ], unique: true
  end
end
