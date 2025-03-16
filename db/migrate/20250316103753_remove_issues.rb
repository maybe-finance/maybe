class RemoveIssues < ActiveRecord::Migration[7.2]
  def change
    drop_table :issues
  end
end
