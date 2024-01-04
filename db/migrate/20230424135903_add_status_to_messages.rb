class AddStatusToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :status, :string, default: 'pending'
  end
end
