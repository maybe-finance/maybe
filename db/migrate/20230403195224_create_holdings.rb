class CreateHoldings < ActiveRecord::Migration[7.1]
  def change
    create_table :holdings, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.references :security, null: false, foreign_key: true, type: :uuid
      t.decimal :value, precision: 19, scale: 4
      t.decimal :quantity, precision: 36, scale: 18
      t.decimal :cost_basis_source, precision: 23, scale: 8
      t.string :currency_code
      t.string :source_id
      t.boolean :excluded, default: false
      t.string :source, null: false

      t.timestamps
    end

    add_index :holdings, [:account_id, :security_id], unique: true
  end
end
