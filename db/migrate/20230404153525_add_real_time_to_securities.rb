class AddRealTimeToSecurities < ActiveRecord::Migration[7.1]
  def change
    add_column :securities, :real_time_price, :decimal, precision: 10, scale: 2
    add_column :securities, :real_time_price_updated_at, :datetime, default: nil
  end
end
