class AddIsActiveToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :is_active, :boolean, default: true, null: false
  end
end
