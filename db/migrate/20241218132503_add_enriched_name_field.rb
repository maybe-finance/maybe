class AddEnrichedNameField < ActiveRecord::Migration[7.2]
  def change
    add_column :account_entries, :enriched_name, :string

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE account_entries ae
          SET name = CASE ae.entryable_type
            WHEN 'Account::Trade' THEN
              CASE
                WHEN EXISTS (
                  SELECT 1 FROM account_trades t
                  WHERE t.id = ae.entryable_id AND t.qty < 0
                ) THEN 'Sell trade'
                ELSE 'Buy trade'
              END
            WHEN 'Account::Transaction' THEN
              CASE
                WHEN ae.amount > 0 THEN 'Expense'
                ELSE 'Income'
              END
            WHEN 'Account::Valuation' THEN 'Balance update'
            ELSE 'Unknown entry'
          END
          WHERE name IS NULL
        SQL

        change_column_null :account_entries, :name, false
      end

      dir.down do
        change_column_null :account_entries, :name, true
      end
    end
  end
end
