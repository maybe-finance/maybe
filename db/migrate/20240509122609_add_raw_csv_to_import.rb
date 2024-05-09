class AddRawCsvToImport < ActiveRecord::Migration[7.2]
  def change
    add_column :imports, :raw_csv, :string
  end
end
