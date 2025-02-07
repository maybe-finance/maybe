class AddExchangeToImportRows < ActiveRecord::Migration[7.2]
  def change
    add_column :import_rows, :exchange, :string
  end
end
