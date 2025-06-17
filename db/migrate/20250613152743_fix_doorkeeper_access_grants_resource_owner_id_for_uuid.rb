class FixDoorkeeperAccessGrantsResourceOwnerIdForUuid < ActiveRecord::Migration[7.2]
  def up
    change_column :oauth_access_grants, :resource_owner_id, :string
  end

  def down
    change_column :oauth_access_grants, :resource_owner_id, :bigint
  end
end
