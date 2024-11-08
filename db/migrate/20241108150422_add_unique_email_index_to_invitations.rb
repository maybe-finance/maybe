class AddUniqueEmailIndexToInvitations < ActiveRecord::Migration[7.2]
  def change
    add_index :invitations, [ :email, :family_id ], unique: true
  end
end
