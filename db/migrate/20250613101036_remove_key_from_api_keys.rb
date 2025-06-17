class RemoveKeyFromApiKeys < ActiveRecord::Migration[7.2]
  def change
    remove_column :api_keys, :key, :string
  end
end
