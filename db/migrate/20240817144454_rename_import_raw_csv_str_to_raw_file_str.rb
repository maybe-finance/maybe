class RenameImportRawCsvStrToRawFileStr < ActiveRecord::Migration[7.2]
  def change
    rename_column :imports, :raw_csv_str, :raw_file_str
  end
end
