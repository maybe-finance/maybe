class AddIndexesToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_index :transactions, :source_transaction_id, unique: true
  end
end
