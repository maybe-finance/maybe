class AddDisplayKeyToApiKeys < ActiveRecord::Migration[7.2]
  def change
    add_column :api_keys, :display_key, :string, null: false
    add_index :api_keys, :display_key, unique: true
  end
end
