class CreateSecurities < ActiveRecord::Migration[7.2]
  def change
    create_table :securities, id: :uuid do |t|
      t.string :name
      t.string :symbol
      t.string :exchange
      t.string :mic_code
      t.string :currency_code
      t.decimal :real_time_price, precision: 10, scale: 2
      t.datetime :real_time_price_updated_at

      t.timestamps
    end
  end
end
