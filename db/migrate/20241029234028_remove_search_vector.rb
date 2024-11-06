class RemoveSearchVector < ActiveRecord::Migration[7.2]
  def change
    remove_column :securities, :search_vector
  end
end
