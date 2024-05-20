class AddAdminRoleToCurrentUsers < ActiveRecord::Migration[7.2]
  def up
    User.update_all(role: "admin")
  end
end
