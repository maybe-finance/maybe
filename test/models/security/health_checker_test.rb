require "test_helper"

class Security::HealthCheckerTest < ActiveSupport::TestCase
  test "checks all securities that don't have a health check" do
    # Setup
    unchecked_security  = Security.create!(ticker: "AAA")
    recent_security     = Security.create!(ticker: "BBB", last_health_check_at: 5.days.ago)
    due_security        = Security.create!(ticker: "CCC", last_health_check_at: Security::HealthChecker::HEALTH_CHECK_INTERVAL.ago - 1.day)

    scope = Security::HealthChecker.send(:never_checked_scope)

    assert_includes scope, unchecked_security
    refute_includes scope, recent_security
    refute_includes scope, due_security
  end

  # We don't intend to check all securities every day
  test "checks oldest DAILY_BATCH_SIZE securities that haven't been checked in HEALTH_CHECK_INTERVAL days" do
    batch_size = Security::HealthChecker::DAILY_BATCH_SIZE

    # Create batch_size + 2 securities that are all past the health check interval so that
    # the scope needs to apply the LIMIT and ordering.
    (batch_size + 2).times do |i|
      # Spread the dates so we can assert ordering (older first)
      days_past_interval = Security::HealthChecker::HEALTH_CHECK_INTERVAL + i.days + 1.day
      Security.create!(ticker: "SEC#{i}", last_health_check_at: days_past_interval.ago)
    end

    scoped = Security::HealthChecker.send(:due_for_check_scope).to_a

    # 1. Only DAILY_BATCH_SIZE records are returned
    assert_equal batch_size, scoped.size

    # 2. Records are ordered oldest -> newest by last_health_check_at
    ordered_dates = scoped.map(&:last_health_check_at)
    assert_equal ordered_dates.sort, ordered_dates, "due_for_check_scope should return oldest records first"

    # 3. The newest (least old) security should have been excluded due to the LIMIT
    newest_excluded_date = Security.order(last_health_check_at: :desc).where(last_health_check_at: ..Security::HealthChecker::HEALTH_CHECK_INTERVAL.ago).first.last_health_check_at
    refute_includes scoped.map(&:last_health_check_at), newest_excluded_date
  end
end
