class CreateMetrics < ActiveRecord::Migration[7.2]
  def change
    create_table :metrics, id: :uuid do |t|
      t.references :family, null: false, foreign_key: true, type: :uuid
      t.references :account, foreign_key: true, type: :uuid, null: true
      t.string :kind, null: false
      t.string :subkind
      t.date :date, null: false
      t.decimal :value, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end
end
