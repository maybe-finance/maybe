class TableRenames < ActiveRecord::Migration[7.2]
  def change
    # Entryables
    rename_table :account_entries, :entries
    rename_table :account_trades, :trades
    rename_table :account_valuations, :valuations
    rename_table :account_transactions, :transactions

    rename_table :account_balances, :balances
    rename_table :account_holdings, :holdings
  end
end
