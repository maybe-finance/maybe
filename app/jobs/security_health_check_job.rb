class SecurityHealthCheckJob < ApplicationJob
  queue_as :scheduled

  def perform
    Security::HealthChecker.check_all
  end
end
