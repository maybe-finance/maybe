require "test_helper"

class NoopApiRateLimiterTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    # Clean up any existing API keys for this user to ensure tests start fresh
    @user.api_keys.destroy_all

    @api_key = ApiKey.create!(
      user: @user,
      name: "Noop Rate Limiter Test Key",
      scopes: [ "read" ],
      display_key: "noop_rate_limiter_test_#{SecureRandom.hex(8)}"
    )
    @rate_limiter = NoopApiRateLimiter.new(@api_key)
  end

  test "should never be rate limited" do
    assert_not @rate_limiter.rate_limit_exceeded?
  end

  test "should not increment request count" do
    @rate_limiter.increment_request_count!
    assert_equal 0, @rate_limiter.current_count
  end

  test "should always have zero request count" do
    assert_equal 0, @rate_limiter.current_count
  end

  test "should have infinite rate limit" do
    assert_equal Float::INFINITY, @rate_limiter.rate_limit
  end

  test "should have zero reset time" do
    assert_equal 0, @rate_limiter.reset_time
  end

  test "should provide correct usage info" do
    usage_info = @rate_limiter.usage_info

    assert_equal 0, usage_info[:current_count]
    assert_equal Float::INFINITY, usage_info[:rate_limit]
    assert_equal Float::INFINITY, usage_info[:remaining]
    assert_equal 0, usage_info[:reset_time]
    assert_equal :noop, usage_info[:tier]
  end

  test "class method usage_for should work" do
    usage_info = NoopApiRateLimiter.usage_for(@api_key)

    assert_equal 0, usage_info[:current_count]
    assert_equal Float::INFINITY, usage_info[:rate_limit]
    assert_equal Float::INFINITY, usage_info[:remaining]
    assert_equal 0, usage_info[:reset_time]
    assert_equal :noop, usage_info[:tier]
  end
end
