class RemoveSelfHostUpgrades < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :last_prompted_upgrade_commit_sha
    remove_column :users, :last_alerted_upgrade_commit_sha
  end
end
