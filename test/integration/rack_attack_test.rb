# frozen_string_literal: true

require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  test "rack attack is configured" do
    # Verify Rack::Attack is enabled in middleware stack
    middleware_classes = Rails.application.middleware.map(&:klass)
    assert_includes middleware_classes, Rack::Attack, "Rack::Attack should be in middleware stack"
  end

  test "oauth token endpoint has rate limiting configured" do
    # Test that the throttle is configured (we don't need to trigger it)
    throttles = Rack::Attack.throttles.keys
    assert_includes throttles, "oauth/token", "OAuth token endpoint should have rate limiting"
  end

  test "api requests have rate limiting configured" do
    # Test that API rate limiting is configured
    throttles = Rack::Attack.throttles.keys
    assert_includes throttles, "api/requests", "API requests should have rate limiting"
  end
end
