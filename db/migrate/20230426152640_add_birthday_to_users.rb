class AddBirthdayToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :birthday, :date
  end
end
