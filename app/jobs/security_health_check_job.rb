class SecurityHealthCheckJob < ApplicationJob
  queue_as :scheduled

  def perform
    return if Rails.env.development?

    Security::HealthChecker.check_all
  end
end
