class CreateFamilySnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :family_snapshots, id: :uuid do |t|
      t.references :family, null: false, type: :uuid, foreign_key: { on_delete: :cascade }

      t.date :date, null: false
      t.string :currency, default: "USD", null: false

      t.decimal :net_worth, precision: 19, scale: 4, null: false, default: 0
      t.decimal :assets, precision: 19, scale: 4, null: false, default: 0
      t.decimal :liabilities, precision: 19, scale: 4, null: false, default: 0
      t.decimal :credits, precision: 19, scale: 4, null: false, default: 0
      t.decimal :depositories, precision: 19, scale: 4, null: false, default: 0
      t.decimal :investments, precision: 19, scale: 4, null: false, default: 0
      t.decimal :loans, precision: 19, scale: 4, null: false, default: 0
      t.decimal :other_assets, precision: 19, scale: 4, null: false, default: 0
      t.decimal :other_liabilities, precision: 19, scale: 4, null: false, default: 0
      t.decimal :properties, precision: 19, scale: 4, null: false, default: 0
      t.decimal :vehicles, precision: 19, scale: 4, null: false, default: 0

      t.timestamps
    end

    add_index :family_snapshots, [ :family_id, :date ], unique: true
  end
end
