class CreateBalances < ActiveRecord::Migration[7.1]
  def change
    create_table :balances, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :security, null: true, foreign_key: true, type: :uuid
      t.decimal :balance, precision: 23, scale: 8
      t.decimal :quantity, precision: 36, scale: 18
      t.decimal :cost_basis, precision: 23, scale: 8
      t.date :date, null: false

      t.timestamps
    end

    add_index :balances, [:account_id, :security_id, :date], unique: true, name: 'index_balances_on_account_id_and_security_id_and_date'
  end
end
