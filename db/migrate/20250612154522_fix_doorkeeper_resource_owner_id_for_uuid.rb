class FixDoorkeeperResourceOwnerIdForUuid < ActiveRecord::Migration[7.1]
  def up
    change_column :oauth_access_tokens, :resource_owner_id, :string
  end

  def down
    change_column :oauth_access_tokens, :resource_owner_id, :integer
  end
end
