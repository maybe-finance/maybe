class TimeSeries
  DIRECTIONS = %w[up down].freeze

  attr_reader :values, :favorable_direction

  def self.from_collection(collection, value_method, favorable_direction: "up")
    collection.map do |obj|
      {
        date: obj.date,
        value: obj.public_send(value_method),
        original: obj
      }
    end.then { |data| new(data, favorable_direction: favorable_direction) }
  end

  def initialize(data, favorable_direction: "up")
    @favorable_direction = (favorable_direction.presence_in(DIRECTIONS) || "up").inquiry
    @values = initialize_values data.sort_by { |d| d[:date] }
  end

  def first
    values.first
  end

  def last
    values.last
  end

  def on(date)
    values.find { |v| v.date == date }
  end

  def trend
    TimeSeries::Trend.new \
      current: last&.value,
      previous: first&.value,
      series: self
  end

  # `as_json` returns the data shape used by D3 charts
  def as_json
    {
      values: values.map(&:as_json),
      trend: trend.as_json,
      favorable_direction: favorable_direction
    }.as_json
  end

  private
    def initialize_values(data)
      [ nil, *data ].each_cons(2).map do |previous, current|
        TimeSeries::Value.new **current,
          previous_value: previous.try(:[], :value),
          series: self
      end
    end
end
