class AutoUpgradeJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Upgrader.attempt_auto_upgrade
  end
end
