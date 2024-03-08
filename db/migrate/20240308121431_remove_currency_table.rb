class RemoveCurrencyTable < ActiveRecord::Migration[7.2]
  def change
    drop_table :currencies
  end
end
