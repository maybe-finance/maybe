# There are hundreds of thousands of market securities that Maybe must handle.
# Due to the always-changing nature of the market, the health checker is responsible
# for periodically checking active securities to ensure we can still fetch prices for them.
#
# Each security goes through some basic health checks.  If failed, this class is responsible for:
# - Marking failed attempts and incrementing the failed attempts counter
# - Marking the security offline if enough consecutive failed checks occur
# - When we move a security "offline", delete all prices for that security as we assume they are bad data
#
# The health checker is run daily through SecurityHealthCheckJob (see config/schedule.yml), but not all
# securities will be checked every day (we run in batches)
class Security::HealthChecker
  MAX_CONSECUTIVE_FAILURES = 5
  HEALTH_CHECK_INTERVAL = 7.days
  DAILY_BATCH_SIZE = 1000

  class << self
    def check_all
      # No daily limit for unchecked securities (they are prioritized)
      never_checked_scope.find_each do |security|
        new(security).run_check
      end

      # Daily limit for checked securities
      due_for_check_scope.limit(DAILY_BATCH_SIZE).each do |security|
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
      end
  end

  def initialize(security)
    @security = security
  end

  def run_check
    Rails.logger.info("Running health check for #{security.ticker}")

    if latest_provider_price
      handle_success
    else
      handle_failure
    end
  rescue => e
    Sentry.capture_exception(e) do |scope|
      scope.set_tags(security_id: @security.id)
    end
  ensure
    security.update!(last_health_check_at: Time.current)
  end

  private
    attr_reader :security

    def provider
      Security.provider
    end

    def latest_provider_price
      return nil unless provider.present?

      response = provider.fetch_security_price(
        symbol: security.ticker,
        exchange_operating_mic: security.exchange_operating_mic,
        date: Date.current
      )

      return nil unless response.success?

      response.data.price
    end

    # On success, reset any failure counters and ensure it is "online"
    def handle_success
      security.update!(
        offline: false,
        failed_fetch_count: 0,
        failed_fetch_at: nil
      )
    end

    def handle_failure
      new_failure_count = security.failed_fetch_count.to_i + 1
      new_failure_at = Time.current

      if new_failure_count > MAX_CONSECUTIVE_FAILURES
        convert_to_offline_security!
      else
        security.update!(
          failed_fetch_count: new_failure_count,
          failed_fetch_at: new_failure_at
        )
      end
    end

    # The "offline" state tells our MarketDataImporter (daily cron) to skip this security when fetching prices
    def convert_to_offline_security!
      Security.transaction do
        security.update!(
          offline: true,
          failed_fetch_count: MAX_CONSECUTIVE_FAILURES + 1,
          failed_fetch_at: Time.current
        )
        security.prices.delete_all
      end
    end
end
