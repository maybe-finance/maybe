class AutoUpgradeJob < ApplicationJob
  queue_as :latency_low

  def perform(*args)
    raise_if_disabled

    return Rails.logger.info "Skipping auto-upgrades because app is set to manual upgrades.  Please set UPGRADES_MODE=auto to enable auto-upgrades" if Setting.upgrades_mode == "manual"

    Rails.logger.info "Searching for available auto-upgrades..."

    candidate = Upgrader.available_upgrade_by_type(Setting.upgrades_target)

    if candidate
      if Rails.cache.read("last_auto_upgrade_commit_sha") == candidate.commit_sha
        Rails.logger.info "Skipping auto upgrade: #{candidate.type} #{candidate.commit_sha} deploy in progress"
        return
      end

      Rails.logger.info "Auto upgrading to #{candidate.type} #{candidate.commit_sha}..."
      Upgrader.upgrade_to(candidate)
      Rails.cache.write("last_auto_upgrade_commit_sha", candidate.commit_sha, expires_in: 1.day)
    else
      Rails.logger.info "No auto upgrade available at this time"
    end
  end

  private
    def raise_if_disabled
      raise "Upgrades module is disabled.  Please set UPGRADES_ENABLED=true to enable upgrade features" unless ENV["UPGRADES_ENABLED"] == "true"
    end
end
