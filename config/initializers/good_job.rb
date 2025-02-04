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

  # 10 queue threads + 3 for job listener, cron, executor = 13 threads allocated
  config.good_job.queues = {
    "latency_low" => { max_threads: 3, priority: 10 }, # ~30s jobs
    "latency_low,latency_medium" => { max_threads: 4, priority: 5 }, # ~1-2 min jobs
    "latency_low,latency_medium,latency_high" => { max_threads: 2, priority: 1 }, # ~5+ min jobs
    "*" => { max_threads: 1, priority: 0 } # fallback queue
  }

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
