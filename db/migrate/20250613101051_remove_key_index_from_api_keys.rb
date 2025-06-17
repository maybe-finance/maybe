class RemoveKeyIndexFromApiKeys < ActiveRecord::Migration[7.2]
  def change
    remove_index :api_keys, :key if index_exists?(:api_keys, :key)
  end
end
