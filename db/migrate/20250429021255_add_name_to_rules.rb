class AddNameToRules < ActiveRecord::Migration[7.2]
  def change
    add_column :rules, :name, :string
  end
end
