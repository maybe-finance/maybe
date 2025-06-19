class AddKindToTransactions < ActiveRecord::Migration[7.2]
  def change
    add_column :transactions, :kind, :string, null: false, default: "standard"
    add_index :transactions, :kind

    reversible do |dir|
      dir.up do
        # Update transaction kinds based on transfer relationships
        execute <<~SQL
          UPDATE transactions
          SET kind = CASE
            WHEN destination_accounts.accountable_type = 'Loan' AND entries.amount > 0 THEN 'loan_payment'
            WHEN destination_accounts.accountable_type = 'CreditCard' AND entries.amount > 0 THEN 'cc_payment'
            ELSE 'funds_movement'
          END
          FROM transfers t
          JOIN entries ON (
            entries.entryable_id = t.inflow_transaction_id OR
            entries.entryable_id = t.outflow_transaction_id
          )
          LEFT JOIN entries inflow_entries ON (
            inflow_entries.entryable_id = t.inflow_transaction_id
            AND inflow_entries.entryable_type = 'Transaction'
          )
          LEFT JOIN accounts destination_accounts ON destination_accounts.id = inflow_entries.account_id
          WHERE transactions.id = entries.entryable_id
            AND entries.entryable_type = 'Transaction'
        SQL
      end
    end
  end
end
