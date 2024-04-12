Rails.application.configure do
  config.good_job.enable_cron = true

  if ENV.fetch("SELF_HOSTING_ENABLED", false)
    config.good_job.cron = {
      auto_upgrade: {
        cron: "every 30 seconds",
        class: "AutoUpgradeJob",
        description: "Check for new versions of the app and upgrade if necessary"
      }
    }
  end
end
