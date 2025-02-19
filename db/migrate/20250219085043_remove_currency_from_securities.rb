class RemoveCurrencyFromSecurities < ActiveRecord::Migration[7.2]
  def change
    remove_index :securities, :currency
    remove_column :securities, :currency, :string
  end
end
