Rails.application.configure do
  config.good_job.enable_cron = true

  if ENV["UPGRADES_ENABLED"] == "true"
    config.good_job.cron = {
      auto_upgrade: {
        cron: "every 30 seconds",
        class: "AutoUpgradeJob",
        description: "Check for new versions of the app and upgrade if necessary"
      }
    }
  end
end
