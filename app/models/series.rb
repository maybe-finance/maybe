class Series
  attr_reader :start_date, :end_date, :interval, :trend, :values

  Value = Struct.new(
    :date,
    :date_formatted,
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
        trend: Trend.new(
          current: ordered.last[:value],
          previous: ordered.first[:value]
        ),
        values: [ nil, *ordered ].each_cons(2).map do |prev_value, curr_value|
          Value.new(
            date: curr_value[:date],
            date_formatted: I18n.l(curr_value[:date], format: :long),
            trend: Trend.new(
              current: curr_value[:value],
              previous: prev_value&.[](:value)
            )
          )
        end
      )
    end
  end

  def initialize(start_date:, end_date:, interval:, trend:, values:)
    @start_date = start_date
    @end_date = end_date
    @interval = interval
    @trend = trend
    @values = values
  end

  def current
    values.last.trend.current
  end

  def any?
    values.any?
  end
end
