class CreateExchangeRates < ActiveRecord::Migration[7.2]
  def change
    create_table :exchange_rates, id: :uuid do |t|
      t.string :base_currency, null: false
      t.string :converted_currency, null: false
      t.decimal :rate
      t.date :date

      t.timestamps
    end

    add_index :exchange_rates, :base_currency
    add_index :exchange_rates, :converted_currency
    add_index :exchange_rates, %i[base_currency converted_currency date], unique: true
  end
end
