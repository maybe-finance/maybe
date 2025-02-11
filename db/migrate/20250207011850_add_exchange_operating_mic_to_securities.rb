class AddExchangeOperatingMicToSecurities < ActiveRecord::Migration[7.2]
  def change
    add_column :securities, :exchange_operating_mic, :string
    add_index :securities, :exchange_operating_mic
  end
end
