class AddOwnerToOauthApplications < ActiveRecord::Migration[7.2]
  def change
    add_column :oauth_applications, :owner_id, :uuid
    add_column :oauth_applications, :owner_type, :string
    add_index :oauth_applications, [ :owner_id, :owner_type ]
  end
end
