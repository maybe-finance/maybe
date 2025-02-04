Rails.application.configure do
  config.good_job.enable_cron = true

  if ENV["UPGRADES_ENABLED"] == "true"
    config.good_job.cron = {
      auto_upgrade: {
        cron: "every 2 minutes",
        class: "AutoUpgradeJob",
        description: "Check for new versions of the app and upgrade if necessary"
      }
    }
  end

  config.good_job.on_thread_error = ->(exception) { Rails.error.report(exception) }

  # 7 dedicated queue threads + 5 catch-all threads + 3 for job listener, cron, executor = 15 threads allocated
  # `latency_low` queue for jobs ~30s
  # `latency_medium` queue for jobs ~1-2 min
  # `latency_high` queue for jobs ~5+ min
  config.good_job.queues = "latency_low:2;latency_low,latency_medium:3;latency_low,latency_medium,latency_high:2;*"

  # Auth for jobs admin dashboard
  ActiveSupport.on_load(:good_job_application_controller) do
    before_action do
      raise ActionController::RoutingError.new("Not Found") unless current_user&.super_admin? || Rails.env.development?
    end

    def current_user
      session = Session.find_by(id: cookies.signed[:session_token])
      session&.user
    end
  end
end
