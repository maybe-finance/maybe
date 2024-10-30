class FixNotNullStockExchangeData < ActiveRecord::Migration[7.2]
  def change
    change_column_null :stock_exchanges, :currency_code, true
    change_column_null :stock_exchanges, :currency_symbol, true
    change_column_null :stock_exchanges, :currency_name, true
    change_column_null :stock_exchanges, :city, true
    change_column_null :stock_exchanges, :timezone_name, true
    change_column_null :stock_exchanges, :timezone_abbr, true
  end
end
