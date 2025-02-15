class AddExchangeOperatingMicToImportRows < ActiveRecord::Migration[7.2]
  def change
    add_column :import_rows, :exchange_operating_mic, :string
  end
end
