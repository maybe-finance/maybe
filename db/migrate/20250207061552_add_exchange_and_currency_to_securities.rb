class AddExchangeAndCurrencyToSecurities < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :currency, :string
    add_index :securities, :currency
  end
end
