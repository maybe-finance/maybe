class AddThemeToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :theme, :string, default: "system"
  end
end
