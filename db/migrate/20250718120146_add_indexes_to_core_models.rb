class AddIndexesToCoreModels < ActiveRecord::Migration[7.2]
  def change
    # Accounts table indexes
    add_index :accounts, [ :family_id, :status ]
    add_index :accounts, :status
    add_index :accounts, :currency

    # Balances table indexes
    add_index :balances, [ :account_id, :date ], order: { date: :desc }

    # Entries table indexes
    add_index :entries, [ :account_id, :date ]
    add_index :entries, :date
    add_index :entries, :entryable_type
    add_index :entries, "lower(name)", name: "index_entries_on_lower_name"

    # Transfers table indexes
    add_index :transfers, :status
  end
end
