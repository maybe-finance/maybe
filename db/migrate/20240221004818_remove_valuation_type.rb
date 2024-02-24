class RemoveValuationType < ActiveRecord::Migration[7.2]
  def change
    remove_column :valuations, :type, :string
  end
end
