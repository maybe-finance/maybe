class ApiRateLimiter
  # Rate limit tiers (requests per hour)
  RATE_LIMITS = {
    standard: 100,
    premium: 1000,
    enterprise: 10000
  }.freeze

  DEFAULT_TIER = :standard

  def initialize(api_key)
    @api_key = api_key
    @redis = Redis.new
  end

  # Check if the API key has exceeded its rate limit
  def rate_limit_exceeded?
    current_count >= rate_limit
  end

  # Increment the request count for this API key
  def increment_request_count!
    key = redis_key
    current_time = Time.current.to_i
    window_start = (current_time / 3600) * 3600 # Hourly window

    @redis.multi do |transaction|
      # Use a sliding window with hourly buckets
      transaction.hincrby(key, window_start.to_s, 1)
      transaction.expire(key, 7200) # Keep data for 2 hours to handle sliding window
    end
  end

  # Get current request count within the current hour
  def current_count
    key = redis_key
    current_time = Time.current.to_i
    window_start = (current_time / 3600) * 3600

    count = @redis.hget(key, window_start.to_s)
    count.to_i
  end

  # Get the rate limit for this API key's tier
  def rate_limit
    tier = determine_tier
    RATE_LIMITS[tier]
  end

  # Calculate seconds until the rate limit resets
  def reset_time
    current_time = Time.current.to_i
    next_window = ((current_time / 3600) + 1) * 3600
    next_window - current_time
  end

  # Get detailed usage information
  def usage_info
    {
      current_count: current_count,
      rate_limit: rate_limit,
      remaining: [ rate_limit - current_count, 0 ].max,
      reset_time: reset_time,
      tier: determine_tier
    }
  end

  # Class method to get usage for an API key without incrementing
  def self.usage_for(api_key)
    new(api_key).usage_info
  end

  private

    def redis_key
      "api_rate_limit:#{@api_key.id}"
    end

    def determine_tier
      # For now, all API keys are standard tier
      # This can be extended later to support different tiers based on user subscription
      # or API key configuration
      DEFAULT_TIER
    end
end
