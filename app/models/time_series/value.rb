class TimeSeries::Value
  include Comparable
  include ActiveModel::Validations

  attr_reader :value, :date, :original, :trend

  validates :date, presence: true
  validate :value_must_be_of_known_type

  def initialize(obj, series: nil, previous: nil)
    @date, @value, @original = parse_object obj
    @series = series
    @trend = create_trend previous

    validate!
  end

  def <=>(other)
    result = date <=> other.date
    result = value <=> other.value if result == 0
    result
  end

  def as_json
    {
      date: date,
      value: value.as_json,
      trend: trend.as_json
    }
  end

  private
    attr_reader :series

    def parse_object(obj)
      if obj.is_a?(Hash)
        date = obj[:date]
        value = obj[:value]
        original = obj.fetch(:original, obj)
      else
        date = obj.date
        value = obj.value
        original = obj
      end

      [ date, value, original ]
    end

    def create_trend(previous)
      TimeSeries::Trend.new \
        current: value,
        previous: previous&.value,
        series: series
    end

    def value_must_be_of_known_type
      unless value.is_a?(Money) || value.is_a?(Numeric)
        errors.add :value, "must be a Money or Numeric"
      end
    end
end
