require "test_helper"

class Security::HealthCheckerTest < ActiveSupport::TestCase
  include ProviderTestHelper

  setup do
    # Clean slate
    Holding.destroy_all
    Trade.destroy_all
    Security::Price.delete_all
    Security.delete_all

    @provider = mock
    Security.stubs(:provider).returns(@provider)

    # Brand new, no health check has been run yet
    @new_security = Security.create!(
      ticker: "NEW",
      offline: false,
      last_health_check_at: nil
    )

    # New security, offline
    # This will be checked, but unless it gets a price, we keep it offline
    @new_offline_security = Security.create!(
      ticker: "NEW_OFFLINE",
      offline: true,
      last_health_check_at: nil
    )

    # Online, recently checked, healthy
    @healthy_security = Security.create!(
      ticker: "HEALTHY",
      offline: false,
      last_health_check_at: 2.hours.ago
    )

    # Online, due for a health check
    @due_for_check_security = Security.create!(
      ticker: "DUE",
      offline: false,
      last_health_check_at: Security::HealthChecker::HEALTH_CHECK_INTERVAL.ago - 1.day
    )

    # Offline, recently checked (keep offline, don't check)
    @offline_security = Security.create!(
      ticker: "OFFLINE",
      offline: true,
      last_health_check_at: 20.days.ago
    )

    # Currently offline, but has had no health check and actually has prices (needs to convert to "online")
    @offline_never_checked_with_prices = Security.create!(
      ticker: "OFFLINE_NEVER_CHECKED",
      offline: true,
      last_health_check_at: nil
    )
  end

  test "any security without a health check runs" do
    to_check = Security.where(last_health_check_at: nil).or(Security.where(last_health_check_at: ..Security::HealthChecker::HEALTH_CHECK_INTERVAL.ago))
    Security::HealthChecker.any_instance.expects(:run_check).times(to_check.count)
    Security::HealthChecker.check_all
  end

  test "offline security with no health check that fails stays offline" do
    hc = Security::HealthChecker.new(@new_offline_security)

    @provider.expects(:fetch_security_price)
      .with(
        symbol: @new_offline_security.ticker,
        exchange_operating_mic: @new_offline_security.exchange_operating_mic,
        date: Date.current
      )
      .returns(
        provider_error_response(StandardError.new("No prices found"))
      )
      .once

    hc.run_check

    assert_equal 1, @new_offline_security.failed_fetch_count
    assert @new_offline_security.offline?
  end

  test "after enough consecutive health check failures, security goes offline and prices are deleted" do
    # Create one test price
    Security::Price.create!(
      security: @due_for_check_security,
      date: Date.current,
      price: 100,
      currency: "USD"
    )

    hc = Security::HealthChecker.new(@due_for_check_security)

    @provider.expects(:fetch_security_price)
      .with(
        symbol: @due_for_check_security.ticker,
        exchange_operating_mic: @due_for_check_security.exchange_operating_mic,
        date: Date.current
      )
      .returns(provider_error_response(StandardError.new("No prices found")))
      .times(Security::HealthChecker::MAX_CONSECUTIVE_FAILURES + 1)

    Security::HealthChecker::MAX_CONSECUTIVE_FAILURES.times do
      hc.run_check
    end

    refute @due_for_check_security.offline?
    assert_equal 1, @due_for_check_security.prices.count

    # We've now exceeded the max consecutive failures, so the security should be marked offline
    hc.run_check
    assert @due_for_check_security.offline?
    assert_equal 0, @due_for_check_security.prices.count
  end

  test "failure incrementor increases for each health check failure" do
    hc = Security::HealthChecker.new(@due_for_check_security)

    @provider.expects(:fetch_security_price)
      .with(
        symbol: @due_for_check_security.ticker,
        exchange_operating_mic: @due_for_check_security.exchange_operating_mic,
        date: Date.current
      )
      .returns(provider_error_response(StandardError.new("No prices found")))
      .twice

    hc.run_check
    assert_equal 1, @due_for_check_security.failed_fetch_count

    hc.run_check
    assert_equal 2, @due_for_check_security.failed_fetch_count
  end

  test "failure incrementor resets to 0 when health check succeeds" do
    hc = Security::HealthChecker.new(@offline_never_checked_with_prices)

    @provider.expects(:fetch_security_price)
      .with(
        symbol: @offline_never_checked_with_prices.ticker,
        exchange_operating_mic: @offline_never_checked_with_prices.exchange_operating_mic,
        date: Date.current
      )
      .returns(provider_success_response(OpenStruct.new(price: 100, date: Date.current, currency: "USD")))
      .once

    assert @offline_never_checked_with_prices.offline?

    hc.run_check

    refute @offline_never_checked_with_prices.offline?
    assert_equal 0, @offline_never_checked_with_prices.failed_fetch_count
    assert_nil @offline_never_checked_with_prices.failed_fetch_at
  end
end
