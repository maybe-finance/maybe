class CreateSecurityPrices < ActiveRecord::Migration[7.2]
  def change
    create_table :security_prices, id: :uuid do |t|
      t.references :security, null: false, foreign_key: true, type: :uuid
      t.date :date, null: false
      t.decimal :open, precision: 20, scale: 11
      t.decimal :high, precision: 20, scale: 11
      t.decimal :low, precision: 20, scale: 11
      t.decimal :close, precision: 20, scale: 11

      t.timestamps
    end
  end
end
