require "test_helper"

class ApiRateLimiterTest < ActiveSupport::TestCase
  setup do
    @user = users(:family_admin)
    # Destroy any existing active API keys for this user
    @user.api_keys.active.destroy_all

    @api_key = ApiKey.create!(
      user: @user,
      name: "Rate Limiter Test Key",
      scopes: [ "read" ],
      display_key: "rate_limiter_test_#{SecureRandom.hex(8)}"
    )
    @rate_limiter = ApiRateLimiter.new(@api_key)

    # Clear any existing rate limit data
    Redis.new.del("api_rate_limit:#{@api_key.id}")
  end

  teardown do
    # Clean up Redis data after each test
    Redis.new.del("api_rate_limit:#{@api_key.id}")
  end

  test "should have default rate limit" do
    assert_equal 100, @rate_limiter.rate_limit
  end

  test "should start with zero request count" do
    assert_equal 0, @rate_limiter.current_count
  end

  test "should not be rate limited initially" do
    assert_not @rate_limiter.rate_limit_exceeded?
  end

  test "should increment request count" do
    assert_equal 0, @rate_limiter.current_count

    @rate_limiter.increment_request_count!
    assert_equal 1, @rate_limiter.current_count

    @rate_limiter.increment_request_count!
    assert_equal 2, @rate_limiter.current_count
  end

  test "should be rate limited when exceeding limit" do
    # Simulate reaching the rate limit
    100.times { @rate_limiter.increment_request_count! }

    assert_equal 100, @rate_limiter.current_count
    assert @rate_limiter.rate_limit_exceeded?
  end

  test "should provide correct usage info" do
    5.times { @rate_limiter.increment_request_count! }

    usage_info = @rate_limiter.usage_info

    assert_equal 5, usage_info[:current_count]
    assert_equal 100, usage_info[:rate_limit]
    assert_equal 95, usage_info[:remaining]
    assert_equal :standard, usage_info[:tier]
    assert usage_info[:reset_time] > 0
    assert usage_info[:reset_time] <= 3600
  end

  test "should calculate remaining requests correctly" do
    10.times { @rate_limiter.increment_request_count! }

    usage_info = @rate_limiter.usage_info
    assert_equal 90, usage_info[:remaining]
  end

  test "should have zero remaining when at limit" do
    100.times { @rate_limiter.increment_request_count! }

    usage_info = @rate_limiter.usage_info
    assert_equal 0, usage_info[:remaining]
  end

  test "should have zero remaining when over limit" do
    105.times { @rate_limiter.increment_request_count! }

    usage_info = @rate_limiter.usage_info
    assert_equal 0, usage_info[:remaining]
  end

  test "class method usage_for should work without incrementing" do
    5.times { @rate_limiter.increment_request_count! }

    usage_info = ApiRateLimiter.usage_for(@api_key)
    assert_equal 5, usage_info[:current_count]

    # Should not increment when just checking usage
    usage_info_again = ApiRateLimiter.usage_for(@api_key)
    assert_equal 5, usage_info_again[:current_count]
  end

  test "should handle multiple API keys separately" do
    # Create a different user for the second API key
    other_user = users(:family_member)
    other_api_key = ApiKey.create!(
      user: other_user,
      name: "Other API Key",
      scopes: [ "read_write" ],
      display_key: "rate_limiter_other_#{SecureRandom.hex(8)}"
    )

    other_rate_limiter = ApiRateLimiter.new(other_api_key)

    @rate_limiter.increment_request_count!
    other_rate_limiter.increment_request_count!
    other_rate_limiter.increment_request_count!

    assert_equal 1, @rate_limiter.current_count
    assert_equal 2, other_rate_limiter.current_count
  ensure
    Redis.new.del("api_rate_limit:#{other_api_key.id}")
    other_api_key.destroy
  end

  test "should calculate reset time correctly" do
    reset_time = @rate_limiter.reset_time

    # Reset time should be within the current hour
    assert reset_time > 0
    assert reset_time <= 3600

    # Should be roughly the time until the next hour
    current_time = Time.current.to_i
    next_window = ((current_time / 3600) + 1) * 3600
    expected_reset = next_window - current_time

    assert_in_delta expected_reset, reset_time, 1
  end
end
