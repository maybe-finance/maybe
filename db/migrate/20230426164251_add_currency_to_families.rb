class AddCurrencyToFamilies < ActiveRecord::Migration[7.1]
  def change
    add_column :families, :currency, :string, default: 'USD'
  end
end
