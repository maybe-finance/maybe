class TimeSeries::Value
  include Comparable
  include ActiveModel::Validations

  attr_reader :value, :date, :original, :trend

  validates :date, presence: true
  validate :value_must_be_of_known_type

  def initialize(date:, value:, original: nil, series: nil, previous_value: nil)
    @date, @value, @original, @series = date, value, original, series
    @trend = create_trend previous_value

    validate!
  end

  def <=>(other)
    result = date <=> other.date
    result = value <=> other.value if result == 0
    result
  end

  def as_json
    {
      date: date.iso8601,
      value: value.as_json,
      trend: trend.as_json
    }
  end

  private
    attr_reader :series

    def create_trend(previous_value)
      Trend.new \
        current: value,
        previous: previous_value,
        favorable_direction: series.favorable_direction
    end

    def value_must_be_of_known_type
      unless value.is_a?(Money) || value.is_a?(Numeric)
        errors.add :value, :must_be_a_money_or_numeric
      end
    end
end
