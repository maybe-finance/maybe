class ChangePrimaryIdentifierForSecurity < ActiveRecord::Migration[7.2]
  def change
    rename_column :securities, :symbol, :ticker
    remove_column :securities, :isin, :string
    rename_column :security_prices, :isin, :ticker
  end
end
