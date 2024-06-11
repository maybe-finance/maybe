class Import::Field
  def self.iso_date_validator(value)
    Date.iso8601(value)
    true
  rescue
    false
  end

  def self.bigdecimal_validator(value)
    BigDecimal(value)
    true
  rescue
    false
  end

  attr_reader :key, :label, :validator

  def initialize(key:, label:, is_optional: false, validator: nil)
    @key = key.to_s
    @label = label
    @is_optional = is_optional
    @validator = validator
  end

  def optional?
    @is_optional
  end

  def define_validator(validator = nil, &block)
    @validator = validator || block
  end

  def validate(value)
    return true if validator.nil?
    validator.call(value)
  end
end
