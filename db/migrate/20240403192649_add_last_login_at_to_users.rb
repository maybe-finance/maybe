class AddLastLoginAtToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :last_login_at, :datetime
  end
end
