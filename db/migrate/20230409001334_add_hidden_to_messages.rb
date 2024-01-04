class AddHiddenToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :hidden, :boolean, default: false
  end
end
