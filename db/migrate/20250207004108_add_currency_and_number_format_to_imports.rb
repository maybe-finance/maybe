class AddCurrencyAndNumberFormatToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :imports, :currency, :string, default: "USD"
    add_column :imports, :number_format, :string, default: "1,234.56"
  end
end
