class CreateImports < ActiveRecord::Migration[7.2]
  def change
    create_enum :import_status, %w[pending importing complete failed]

    create_table :imports, id: :uuid do |t|
      t.references :account, null: false, foreign_key: true, type: :uuid
      t.jsonb :column_mappings
      t.enum :status, enum_type: :import_status, default: "pending"
      t.string :raw_csv_str
      t.string :normalized_csv_str

      t.timestamps
    end
  end
end
