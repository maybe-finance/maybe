class AutoUpgradeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Upgrader.attempt_auto_upgrade(Setting.auto_upgrades_mode)
  end
end
