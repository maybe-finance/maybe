class AddTransactionMerchants < ActiveRecord::Migration[7.2]
  def change
    create_table :transaction_merchants, id: :uuid do |t|
      t.string "name", null: false
      t.string "color", default: "#e99537", null: false
      t.references :family, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_reference :transactions, :merchant, foreign_key: { to_table: :transaction_merchants }, type: :uuid
  end
end
