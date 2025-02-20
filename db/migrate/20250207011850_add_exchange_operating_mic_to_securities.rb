class AddExchangeOperatingMicToSecurities < ActiveRecord::Migration[7.2]
  def change
    # Add exchange_operating_mic to securities
    add_column :securities, :exchange_operating_mic, :string
    add_index :securities, :exchange_operating_mic

    # Add exchange_operating_mic_col_label to imports
    add_column :imports, :exchange_operating_mic_col_label, :string

    # Add exchange_operating_mic to import_rows
    add_column :import_rows, :exchange_operating_mic, :string

    # Remove old exchange and currency columns
    remove_column :import_rows, :exchange, :string
    remove_column :imports, :exchange_col_label, :string
    remove_index :securities, :currency if index_exists?(:securities, :currency)
    remove_column :securities, :currency, :string

    # Adjust securities indexes
    remove_index :securities, name: "index_securities_on_ticker_and_exchange_mic" if index_exists?(:securities, [ :ticker, :exchange_mic ], name: "index_securities_on_ticker_and_exchange_mic")
    add_index :securities, [ :ticker, :exchange_operating_mic ], unique: true
  end
end
