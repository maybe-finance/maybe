class SecurityHealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    Security::HealthChecker.new.perform
  end
end
