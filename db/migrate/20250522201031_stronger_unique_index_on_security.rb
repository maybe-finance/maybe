class StrongerUniqueIndexOnSecurity < ActiveRecord::Migration[7.2]
  def change
    remove_index :securities, [ :ticker, :exchange_operating_mic ], unique: true

    # Matches our ActiveRecord validation:
    # - uppercase ticker
    # - either exchange_operating_mic or empty string (unique index doesn't work with NULL values)
    add_index :securities,
              "UPPER(ticker), COALESCE(UPPER(exchange_operating_mic), '')",
              unique: true,
              name: "index_securities_on_ticker_and_exchange_operating_mic_unique"
  end
end
