class AddSourceToApiKeys < ActiveRecord::Migration[7.2]
  def change
    add_column :api_keys, :source, :string, default: "web"
    add_index :api_keys, [ :user_id, :source ]
  end
end
