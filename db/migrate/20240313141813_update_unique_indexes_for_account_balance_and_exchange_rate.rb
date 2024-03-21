class UpdateUniqueIndexesForAccountBalanceAndExchangeRate < ActiveRecord::Migration[7.2]
  def change
    rename_index :exchange_rates, 'idx_on_base_currency_converted_currency_date_255be792be', 'index_exchange_rates_on_base_converted_date_unique'
    remove_index :account_balances, name: "index_account_balances_on_account_id_and_date"
    add_index :account_balances, [ :account_id, :date, :currency ], unique: true, name: "index_account_balances_on_account_id_date_currency_unique"
  end
end
