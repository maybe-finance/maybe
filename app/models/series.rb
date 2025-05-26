class Series
  # Behave like an Array whose elements are the `Value` structs stored in `values`
  include Enumerable

  # Forward any undefined method calls (e.g. `first`, `[]`, `map`) to `values`
  delegate_missing_to :values

  # Enumerable needs `#each`
  def each(&block)
    values.each(&block)
  end

  attr_reader :start_date, :end_date, :interval, :trend, :values, :favorable_direction

  Value = Struct.new(
    :date,
    :date_formatted,
    :value,
    :trend,
    keyword_init: true
  )

  class << self
    def from_raw_values(values, interval: "1 day")
      raise ArgumentError, "Must be an array of at least 2 values" unless values.size >= 2
      raise ArgumentError, "Must have date and value properties" unless values.all? { |value| value.has_key?(:date) && value.has_key?(:value) }

      ordered = values.sort_by { |value| value[:date] }
      start_date = ordered.first[:date]
      end_date = ordered.last[:date]

      new(
        start_date: start_date,
        end_date: end_date,
        interval: interval,
        values: [ nil, *ordered ].each_cons(2).map do |prev_value, curr_value|
          Value.new(
            date: curr_value[:date],
            date_formatted: I18n.l(curr_value[:date], format: :long),
            value: curr_value[:value],
            trend: Trend.new(
              current: curr_value[:value],
              previous: prev_value&.[](:value)
            )
          )
        end
      )
    end
  end

  def initialize(start_date:, end_date:, interval:, values:, favorable_direction: "up")
    @start_date = start_date
    @end_date = end_date
    @interval = interval
    @values = values
    @favorable_direction = favorable_direction
  end

  def trend
    @trend ||= Trend.new(
      current: values.last&.value,
      previous: values.first&.value,
      favorable_direction: favorable_direction
    )
  end

  def as_json
    {
      start_date: start_date,
      end_date: end_date,
      interval: interval,
      trend: trend,
      values: values.map { |v| { date: v.date, date_formatted: v.date_formatted, value: v.value, trend: v.trend } }
    }
  end
end
