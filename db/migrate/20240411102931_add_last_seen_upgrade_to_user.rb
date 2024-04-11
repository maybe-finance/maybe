class AddLastSeenUpgradeToUser < ActiveRecord::Migration[7.2]
  def change
    # Self-hosted users will be prompted to upgrade to the latest commit or release.
    add_column :users, :last_prompted_upgrade_commit_sha, :string

    # All users will be notified when a new commit or release has successfully been deployed.
    add_column :users, :last_alerted_upgrade_commit_sha, :string
  end
end
