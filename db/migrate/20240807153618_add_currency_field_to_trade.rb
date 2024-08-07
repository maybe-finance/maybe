class AddCurrencyFieldToTrade < ActiveRecord::Migration[7.2]
  def change
    add_column :account_trades, :currency, :string
  end
end
