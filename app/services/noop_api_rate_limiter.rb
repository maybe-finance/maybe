class NoopApiRateLimiter
  def initialize(api_key)
    @api_key = api_key
  end

  def rate_limit_exceeded?
    false
  end

  def increment_request_count!
    # No operation
  end

  def current_count
    0
  end

  def rate_limit
    Float::INFINITY
  end

  def reset_time
    0
  end

  def usage_info
    {
      current_count: 0,
      rate_limit: Float::INFINITY,
      remaining: Float::INFINITY,
      reset_time: 0,
      tier: :noop
    }
  end

  def self.usage_for(api_key)
    new(api_key).usage_info
  end
end
