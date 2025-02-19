class RemoveExchangeFromImportRows < ActiveRecord::Migration[7.2]
  def change
    remove_column :import_rows, :exchange, :string
  end
end
