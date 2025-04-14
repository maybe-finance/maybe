class TableRenames < ActiveRecord::Migration[7.2]
  def change
    # Entryables
    rename_table :account_entries, :entries
    rename_table :account_trades, :trades
    rename_table :account_valuations, :valuations
    rename_table :account_transactions, :transactions

    rename_table :account_balances, :balances
    rename_table :account_holdings, :holdings

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE entries
          SET entryable_type = CASE
            WHEN entryable_type = 'Account::Transaction' THEN 'Transaction'
            WHEN entryable_type = 'Account::Trade' THEN 'Trade'
            WHEN entryable_type = 'Account::Valuation' THEN 'Valuation'
          END
        SQL

        execute <<~SQL
          UPDATE taggings
          SET taggable_type = CASE
            WHEN taggable_type = 'Account::Transaction' THEN 'Transaction'
          END
        SQL
      end

      dir.down do
        execute <<~SQL
          UPDATE entries
          SET entryable_type = CASE
            WHEN entryable_type = 'Transaction' THEN 'Account::Transaction'
            WHEN entryable_type = 'Trade' THEN 'Account::Trade'
            WHEN entryable_type = 'Valuation' THEN 'Account::Valuation'
          END
        SQL

        execute <<~SQL
          UPDATE taggings
          SET taggable_type = CASE
            WHEN taggable_type = 'Transaction' THEN 'Account::Transaction'
          END
        SQL
      end
    end
  end
end
