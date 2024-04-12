class AutoUpgradeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    raise_if_disabled

    return Rails.logger.info "Skipping auto-upgrades because app is set to manual upgrades.  Please set UPGRADES_MODE=auto to enable auto-upgrades" if Setting.upgrades_mode == "manual"

    Rails.logger.info "Searching for available auto-upgrades..."

    Upgrader.attempt_latest_upgrade(Setting.upgrades_target)
  end

  private
    def raise_if_disabled
      raise "Upgrades module is disabled.  Please set UPGRADES_ENABLED=true to enable upgrade features" unless ENV["UPGRADES_ENABLED"] == "true"
    end
end
