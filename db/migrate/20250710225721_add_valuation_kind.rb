class AddValuationKind < ActiveRecord::Migration[7.2]
  def up
    add_column :valuations, :kind, :string, default: "reconciliation", null: false
    add_column :valuations, :balance, :decimal, precision: 16, scale: 4
    add_column :valuations, :cash_balance, :decimal, precision: 16, scale: 4

    # Copy `amount` from Entry, set both `balance` and `cash_balance` to the same value on all Valuation records, and `currency` from Entry to Valuation
    execute <<-SQL
      UPDATE valuations
      SET
        balance = entries.amount,
        -- Depository/CC accounts are "all cash" accounts where their cash balance == balance
        cash_balance = CASE WHEN accounts.accountable_type IN ('Depository', 'CreditCard') THEN entries.amount ELSE 0 END
      FROM entries
      JOIN accounts ON entries.account_id = accounts.id
      WHERE entries.entryable_type = 'Valuation' AND entries.entryable_id = valuations.id
    SQL

    change_column_null :valuations, :kind, false
    change_column_null :valuations, :balance, false
    change_column_null :valuations, :cash_balance, false
  end

  def down
    remove_column :valuations, :kind
    remove_column :valuations, :balance
    remove_column :valuations, :cash_balance
  end
end
