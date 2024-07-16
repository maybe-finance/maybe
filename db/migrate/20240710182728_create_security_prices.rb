class CreateSecurityPrices < ActiveRecord::Migration[7.2]
  def change
    create_table :security_prices, id: :uuid do |t|
      t.string :isin
      t.date :date
      t.decimal :price, precision: 19, scale: 4
      t.string :currency, default: "USD"

      t.timestamps
    end
  end
end
