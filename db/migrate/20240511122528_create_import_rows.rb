class CreateImportRows < ActiveRecord::Migration[7.2]
  def change
    create_table :import_rows, id: :uuid do |t|
      t.references :import, null: false, foreign_key: true, type: :uuid
      t.string :date
      t.string :name
      t.string :category
      t.string :merchant
      t.string :amount

      t.timestamps
    end
  end
end
