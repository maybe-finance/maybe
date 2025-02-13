class AddUserSidebarPreference < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :show_sidebar, :boolean, default: true
  end
end
