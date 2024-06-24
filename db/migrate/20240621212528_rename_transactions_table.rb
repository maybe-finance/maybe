class RenameTransactionsTable < ActiveRecord::Migration[7.2]
  def change
    rename_table :transactions, :account_transactions

    reversible do |dir|
      dir.up do
        Tagging.where(taggable_type: 'Transaction').update_all(taggable_type: "Account::Transaction")
      end

      dir.down do
        Tagging.where(taggable_type: 'Account::Transaction').update_all(taggable_type: "Transaction")
      end
    end
  end
end
