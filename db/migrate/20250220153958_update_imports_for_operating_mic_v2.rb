class UpdateImportsForOperatingMicV2 < ActiveRecord::Migration[7.2]
  def up
    # First remove the old exchange columns if they exist
    remove_column :import_rows, :exchange if column_exists?(:import_rows, :exchange)
    remove_column :imports, :exchange_col_label if column_exists?(:imports, :exchange_col_label)

    # Then remove and re-add the operating mic columns to ensure they're in the correct state
    remove_column :import_rows, :exchange_operating_mic if column_exists?(:import_rows, :exchange_operating_mic)
    remove_column :imports, :exchange_operating_mic_col_label if column_exists?(:imports, :exchange_operating_mic_col_label)

    # Add the columns fresh
    add_column :import_rows, :exchange_operating_mic, :string
    add_column :imports, :exchange_operating_mic_col_label, :string
  end

  def down
    # Remove the new columns
    remove_column :import_rows, :exchange_operating_mic
    remove_column :imports, :exchange_operating_mic_col_label

    # Add back the old columns
    add_column :import_rows, :exchange, :string
    add_column :imports, :exchange_col_label, :string
  end
end
