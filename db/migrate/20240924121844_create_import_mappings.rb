class CreateImportMappings < ActiveRecord::Migration[7.2]
  def change
    create_table :import_mappings, id: :uuid do |t|
      t.string :key
      t.string :type
      t.boolean :create_when_empty, default: false
      t.references :import, null: false, type: :uuid
      t.references :mappable, polymorphic: true, type: :uuid

      t.timestamps
    end
  end
end
