class AddStatusToAccount < ActiveRecord::Migration[7.2]
  def change
    add_column :accounts, :status, :string, default: "OK"
  end
end
