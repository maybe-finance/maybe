class CreateSecurityPrices < ActiveRecord::Migration[7.1]
  def change
    create_table :security_prices, id: :uuid do |t|
      t.references :security, null: false, foreign_key: true, type: :uuid
      t.date :date, null: false
      t.decimal :open, precision: 20, scale: 11
      t.decimal :high, precision: 20, scale: 11
      t.decimal :low, precision: 20, scale: 11
      t.decimal :close, precision: 20, scale: 11
      t.string :currency, default: 'USD'
      t.string :exchange
      t.string :kind

      t.timestamps
    end

    add_index :security_prices, [:security_id, :date], unique: true
  end
end
