class Measurement
  include ActiveModel::Validations

  attr_reader :value, :unit

  VALID_UNITS = %w[sqft sqm mi km]

  validates :unit, inclusion: { in: VALID_UNITS }
  validates :value, presence: true

  def initialize(value, unit)
    @value = value.to_f
    @unit = unit.to_s.downcase.strip
    validate!
  end

  def to_s
    "#{@value.to_i} #{@unit}"
  end
end
