class AddAccountToImportRow < ActiveRecord::Migration[7.2]
  def change
    add_column :import_rows, :account, :string
  end
end
