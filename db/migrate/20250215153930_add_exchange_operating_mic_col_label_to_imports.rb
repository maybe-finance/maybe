class AddExchangeOperatingMicColLabelToImports < ActiveRecord::Migration[7.2]
  def up
    add_column :imports, :exchange_operating_mic_col_label, :string
  end

  def down
    remove_column :imports, :exchange_operating_mic_col_label
  end
end
