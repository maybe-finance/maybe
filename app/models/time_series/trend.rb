class TimeSeries::Trend
  attr_reader :type

  # Tells us whether an increasing/decreasing trend is good or bad (i.e. a liability decreasing is good)
  TYPES = %i[normal inverse].freeze

  def initialize(current: nil, previous: nil, type: :normal)
    validate_data_types(current, previous)
    validate_type(type)
    @current = current
    @previous = previous
    @type = type
  end

  def direction
    return "flat" if @current == @previous || @previous.nil?
    return "up" if @current && @current > @previous
    "down"
  end

  def value
    return Money.new(0) if @previous.nil? && @current.is_a?(Money)
    return 0 if @previous.nil?
    @current - @previous
  end

  def percent
    return 0 if @previous.nil?
    return Float::INFINITY if @previous == 0
    ((extract_numeric(@current) - extract_numeric(@previous)).abs / extract_numeric(@previous).abs.to_f * 100).round(1)
  end

  private
    def validate_type(type)
      raise ArgumentError, "Invalid type" unless TYPES.include?(type)
    end

    def validate_data_types(current, previous)
      return if previous.nil? || current.nil?
      raise ArgumentError, "Current and previous values must be of the same type" unless current.class == previous.class
      raise ArgumentError, "Current and previous values must be of type Money or Numeric" unless current.is_a?(Money) || current.is_a?(Numeric)
    end

    def extract_numeric(obj)
      return obj.amount if obj.is_a? Money
      obj
    end
end
