class AddAccountMode < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :mode, :string
  end
end
