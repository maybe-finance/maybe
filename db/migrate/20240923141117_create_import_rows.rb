class CreateImportRows < ActiveRecord::Migration[7.2]
  def change
    create_table :import_rows, id: :uuid do |t|
      t.references :import, null: false, foreign_key: true, type: :uuid
      t.string :type, null: false
      t.string :date
      t.string :qty
      t.string :price
      t.string :amount
      t.string :name
      t.string :category
      t.string :tags
      t.string :trade_type
      t.text :notes

      t.timestamps
    end
  end
end
