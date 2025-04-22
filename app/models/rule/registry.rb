class Rule::Registry
  UnsupportedActionError = Class.new(StandardError)
  UnsupportedConditionError = Class.new(StandardError)

  def initialize(rule)
    @rule = rule
  end

  def resource_scope
    raise NotImplementedError, "#{self.class.name} must implement #resource_scope"
  end

  def condition_filters
    []
  end

  def action_executors
    []
  end

  def get_filter!(key)
    filter = condition_filters.find { |filter| filter.key == key }
    raise UnsupportedConditionError, "Unsupported condition type: #{key}" unless filter
    filter
  end

  def get_executor!(key)
    executor = action_executors.find { |executor| executor.key == key }
    raise UnsupportedActionError, "Unsupported action type: #{key}" unless executor
    executor
  end

  def as_json
    {
      filters: condition_filters.map(&:as_json),
      executors: action_executors.map(&:as_json)
    }
  end

  private
    attr_reader :rule

    def family
      rule.family
    end
end
