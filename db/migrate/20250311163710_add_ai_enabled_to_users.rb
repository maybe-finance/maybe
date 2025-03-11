class AddAiEnabledToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :ai_enabled, :boolean, default: false, null: false
  end
end
