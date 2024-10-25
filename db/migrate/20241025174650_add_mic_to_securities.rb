class AddMicToSecurities < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :exchange_mic, :string
    add_column :securities, :exchange_acronym, :string

    remove_column :securities, :stock_exchange_id, :uuid

    add_index :securities, [ :ticker, :exchange_mic ], unique: true
  end
end
