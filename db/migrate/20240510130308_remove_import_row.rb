class RemoveImportRow < ActiveRecord::Migration[7.2]
  def change
    drop_table :import_rows
  end
end
