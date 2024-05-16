class Import::Field
  attr_reader :key, :label, :validator

  def initialize(key:, label:, validator: nil)
    @key = key.to_s
    @label = label
    @validator = validator
  end

  def define_validator(validator = nil, &block)
    @validator = validator || block
  end

  def validate(value)
    return true if validator.nil?
    validator.call(value)
  end
end
