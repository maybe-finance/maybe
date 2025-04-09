class Rule::ConditionFilter
  UnsupportedOperatorError = Class.new(StandardError)

  TYPES = [ "text", "number", "select" ]

  OPERATORS_MAP = {
    "text" => [ "like", "=" ],
    "number" => [ ">", ">=", "<", "<=", "=" ],
    "select" => [ "=" ]
  }

  def initialize(rule)
    @rule = rule
  end

  def type
    "text"
  end

  def key
    self.class.name.demodulize.underscore
  end

  def label
    key.humanize
  end

  def options
    nil
  end

  def operators
    OPERATORS_MAP.dig(type)
  end

  # Matchers can prepare the scope with joins by implementing this method
  def prepare(scope)
    scope
  end

  # Applies the condition to the scope
  def apply(scope, operator, value)
    raise NotImplementedError, "Condition #{self.class.name} must implement #apply"
  end

  def as_json
    {
      type: type,
      key: key,
      label: label,
      operators: operators,
      options: options
    }
  end

  private
    attr_reader :rule

    def family
      rule.family
    end

    def build_sanitized_where_condition(field, operator, value)
      sanitized_value = operator == "like" ? "%#{ActiveRecord::Base.sanitize_sql_like(value)}%" : value

      ActiveRecord::Base.sanitize_sql_for_conditions([
        "#{field} #{sanitize_operator(operator)} ?",
        sanitized_value
      ])
    end

    def sanitize_operator(operator)
      raise UnsupportedOperatorError, "Unsupported operator: #{operator} for type: #{type}" unless operators.include?(operator)

      if operator == "like"
        "ILIKE"
      else
        operator
      end
    end
end
