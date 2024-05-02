class CreateImports < ActiveRecord::Migration[7.2]
  def change
    create_table :imports, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.jsonb :column_mappings

      t.timestamps
    end
  end
end
