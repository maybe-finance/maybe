module UpgradesHelper
  def upgrade_notification
    return nil unless ENV["UPGRADES_ENABLED"] == "true"

    completed_upgrade = Upgrader.completed_upgrade
    return completed_upgrade if completed_upgrade && Current.user.last_alerted_upgrade_commit_sha != completed_upgrade.commit_sha

    available_upgrade = Upgrader.available_upgrade
    if available_upgrade && Setting.upgrades_mode == "manual" && Current.user.last_prompted_upgrade_commit_sha != available_upgrade.commit_sha
      available_upgrade
    end
  end
end
