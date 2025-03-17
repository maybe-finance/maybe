class RemoveTickerFromSecurityPrices < ActiveRecord::Migration[7.2]
  def change
    remove_column :security_prices, :ticker
  end
end
