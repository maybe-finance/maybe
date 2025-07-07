class AddValuationKindFieldForAnchors < ActiveRecord::Migration[7.2]
  def up
    add_column :valuations, :kind, :string, default: "recon"
    add_column :valuations, :balance, :decimal, precision: 19, scale: 4
    add_column :valuations, :cash_balance, :decimal, precision: 19, scale: 4
    add_column :valuations, :currency, :string

    # Copy `amount` from Entry, set both `balance` and `cash_balance` to the same value on all Valuation records, and `currency` from Entry to Valuation
    execute <<-SQL
      UPDATE valuations
      SET
        balance = entries.amount,
        cash_balance = entries.amount,
        currency = entries.currency
      FROM entries
      WHERE entries.entryable_type = 'Valuation' AND entries.entryable_id = valuations.id
    SQL

    change_column_null :valuations, :kind, false
    change_column_null :valuations, :currency, false
    change_column_null :valuations, :balance, false
    change_column_null :valuations, :cash_balance, false
  end

  def down
    remove_column :valuations, :kind
    remove_column :valuations, :balance
    remove_column :valuations, :cash_balance
    remove_column :valuations, :currency
  end
end
