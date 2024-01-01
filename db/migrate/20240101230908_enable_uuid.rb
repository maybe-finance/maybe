class EnableUuid < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto'
  end
end
