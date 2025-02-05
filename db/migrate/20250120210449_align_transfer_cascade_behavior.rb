class AlignTransferCascadeBehavior < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :transfers, :account_transactions, column: :inflow_transaction_id
    remove_foreign_key :transfers, :account_transactions, column: :outflow_transaction_id

    add_foreign_key :transfers, :account_transactions,
                    column: :inflow_transaction_id,
                    on_delete: :cascade

    add_foreign_key :transfers, :account_transactions,
                    column: :outflow_transaction_id,
                    on_delete: :cascade
  end
end
