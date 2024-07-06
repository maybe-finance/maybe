class RenameRateFields < ActiveRecord::Migration[7.2]
  def change
    rename_column :exchange_rates, :base_currency, :from_currency
    rename_column :exchange_rates, :converted_currency, :to_currency
  end
end
