class RemoveOldColumnsFromEntryables < ActiveRecord::Migration[7.2]
  def change
    # Remove old columns from Account::Transaction
    remove_column :account_transactions, :name, :string
    remove_column :account_transactions, :date, :date
    remove_column :account_transactions, :amount, :decimal, precision: 19, scale: 4
    remove_column :account_transactions, :currency, :string
    remove_column :account_transactions, :account_id, :uuid

    # Remove old columns from Account::Valuation
    remove_column :account_valuations, :date, :date
    remove_column :account_valuations, :value, :decimal, precision: 19, scale: 4
    remove_column :account_valuations, :currency, :string
    remove_column :account_valuations, :account_id, :uuid
  end
end
