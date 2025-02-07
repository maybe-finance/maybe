class AddExchangeAndCurrencyColumnsToImports < ActiveRecord::Migration[7.2]
  def change
    add_column :imports, :exchange_col_label, :string
  end
end
