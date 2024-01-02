class CreateHoldings < ActiveRecord::Migration[7.2]
  def change
    create_table :holdings, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :security, null: false, foreign_key: true, type: :uuid
      t.references :portfolio, null: false, foreign_key: true, type: :uuid
      t.decimal :value, precision: 19, scale: 4
      t.decimal :quantity, precision: 36, scale: 18
      t.decimal :cost_basis, precision: 23, scale: 8

      t.timestamps
    end
  end
end
