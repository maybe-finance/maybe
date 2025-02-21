class UpdateImportsForOperatingMicV2 < ActiveRecord::Migration[7.2]
  def change
    add_column :import_rows, :exchange_operating_mic, :string
    add_column :imports, :exchange_operating_mic_col_label, :string
  end
end
