class CreateCurrencies < ActiveRecord::Migration[7.2]
  def change
    create_table :currencies, id: :uuid do |t|
      t.string :name
      t.string :iso_code

      t.timestamps
    end

    add_index :currencies, :iso_code, unique: true
  end
end
