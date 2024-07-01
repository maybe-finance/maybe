class CreateSecurityPrices < ActiveRecord::Migration[7.2]
  def change
    create_table :security_prices, id: :uuid do |t|
      t.date :date, null: false
      t.decimal :price, precision: 19, scale: 4, null: false
      t.string :currency, null: false, default: "USD"

      t.timestamps
    end
  end
end
