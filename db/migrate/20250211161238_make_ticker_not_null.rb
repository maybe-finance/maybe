class MakeTickerNotNull < ActiveRecord::Migration[7.2]
  def change
    change_column_null :securities, :ticker, false
  end
end
