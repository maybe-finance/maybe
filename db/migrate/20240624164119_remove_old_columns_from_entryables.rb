class RemoveOldColumnsFromEntryables < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up do
        # Remove old columns from Account::Transaction
        remove_column :account_transactions, :name
        remove_column :account_transactions, :date
        remove_column :account_transactions, :amount
        remove_column :account_transactions, :currency
        remove_column :account_transactions, :account_id

        # Remove old columns from Account::Valuation
        remove_column :account_valuations, :date
        remove_column :account_valuations, :value
        remove_column :account_valuations, :currency
        remove_column :account_valuations, :account_id
      end

      dir.down do
        # Add old columns back to Account::Transaction
        add_column :account_transactions, :name, :string
        add_column :account_transactions, :date, :date
        add_column :account_transactions, :amount, :decimal, precision: 19, scale: 4
        add_column :account_transactions, :currency, :string
        add_column :account_transactions, :account_id, :uuid

        # Add old columns back to Account::Valuation
        add_column :account_valuations, :date, :date
        add_column :account_valuations, :value, :decimal, precision: 19, scale: 4
        add_column :account_valuations, :currency, :string
        add_column :account_valuations, :account_id, :uuid

        # Repopulate data for Account::Transaction
        execute <<-SQL.squish
          UPDATE account_transactions at
          SET name = ae.name,
              date = ae.date,
              amount = ae.amount,
              currency = ae.currency,
              account_id = ae.account_id
          FROM account_entries ae
          WHERE ae.entryable_type = 'Account::Transaction' AND ae.entryable_id = at.id
        SQL

        # Repopulate data for Account::Valuation
        execute <<-SQL.squish
          UPDATE account_valuations av
          SET date = ae.date,
              value = ae.amount,
              currency = ae.currency,
              account_id = ae.account_id
          FROM account_entries ae
          WHERE ae.entryable_type = 'Account::Valuation' AND ae.entryable_id = av.id
        SQL
      end
    end
  end
end
