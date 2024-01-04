class AddLogToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :log, :text
  end
end
