class SecurityHealthCheckJob < ApplicationJob
  queue_as :scheduled

  def perform
    Security::HealthChecker.new.perform
  end
end
