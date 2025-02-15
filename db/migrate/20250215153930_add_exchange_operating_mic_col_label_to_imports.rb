class AddExchangeOperatingMicColLabelToImports < ActiveRecord::Migration[7.2]
  def up
    add_column :imports, :exchange_operating_mic_col_label, :string

    # Migrate existing trade imports to use the new column
    Import.where(type: "TradeImport").find_each do |import|
      if import.exchange_col_label.present?
        import.update_column(:exchange_operating_mic_col_label, import.exchange_col_label)
      end
    end
  end

  def down
    remove_column :imports, :exchange_operating_mic_col_label
  end
end
