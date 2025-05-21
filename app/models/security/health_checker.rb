# There are hundreds of thousands of market securities that Maybe must handle.
# Due to the always-changing nature of the market, the health checker is responsible
# for periodically checking active securities to ensure we can still fetch prices for them.
#
# Securities that cannot fetch prices are marked "offline" and will not run price updates.
#
# The health checker is run daily through SecurityHealthCheckJob (see config/schedule.yml)
class Security::HealthChecker
  HEALTH_CHECK_INTERVAL = 30.days
  DAILY_BATCH_SIZE = 1000

  class << self
    def check_all
      # All securities that have never been checked run, regardless of daily batch size
      never_checked_scope.find_each do |security|
        new(security).run_check
      end

      due_for_check_scope.find_each do |security|
        new(security).run_check
      end
    end

    private
      # If a security has never had a health check, we prioritize it, regardless of batch size
      def never_checked_scope
        Security.where(last_health_check_at: nil)
      end

      # Any securities not checked for 30 days are due
      # We only process the batch size, which means some "due" securities will not be checked today
      # This is by design, to prevent all securities from coming due at the same time
      def due_for_check_scope
        Security.where(last_health_check_at: ..HEALTH_CHECK_INTERVAL.ago)
                .order(last_health_check_at: :asc)
                .limit(DAILY_BATCH_SIZE)
      end
  end

  def initialize(security)
    @security = security
  end

  def run_check
  end

  private
    def scope
      Security.where(last_health_check_at: nil)
              .or(Security.where(last_health_check_at: ..7.days.ago))
    end

    def can_fetch_from_provider?
    end

    def has_daily_prices?
    end
end
