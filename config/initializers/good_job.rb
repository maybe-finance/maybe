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

  # Auth for jobs admin dashboard
  ActiveSupport.on_load(:good_job_application_controller) do
    before_action do
      raise ActionController::RoutingError.new("Not Found") unless current_user&.super_admin?
    end

    def current_user
      session = Session.find_by(id: cookies.signed[:session_token])
      session&.user
    end
  end
end
