require "test_helper"

class TimeSeriesTest < ActiveSupport::TestCase
  test "it can accept array of money values" do
    series = TimeSeries.new([ { date: 1.day.ago.to_date, value: Money.new(100) }, { date: Date.current, value: Money.new(200) } ])

    assert_equal Money.new(100), series.first.value
    assert_equal Money.new(200), series.last.value
    assert_equal "up", series.favorable_direction
    assert_equal "up", series.trend.direction
    assert_equal Money.new(100), series.trend.value
    assert_equal 100.0, series.trend.percent
  end

  test "it can accept array of numeric values" do
    series = TimeSeries.new([ { date: 1.day.ago.to_date, value: 100 }, { date: Date.current, value: 200 } ])

    assert_equal 100, series.first.value
    assert_equal 200, series.last.value
    assert_equal "up", series.favorable_direction
    assert_equal "up", series.trend.direction
    assert_equal 100, series.trend.value
    assert_equal 100.0, series.trend.percent
  end

  test "when empty array passed, it returns empty series" do
    series = TimeSeries.new([])

    assert_nil series.first
    assert_nil series.last
    assert_equal({ values: [], trend: { favorable_direction: "up", direction: "flat", value: 0, percent: 0.0 }, favorable_direction: "up" }.to_json, series.to_json)
  end

  test "money series can be serialized to json" do
    expected_values = {
      values: [
        {
          date: 1.day.ago.to_date,
          value: { amount: "100.0", currency: "USD" },
          trend: { favorable_direction: "up", direction: "flat", value: { amount: "0.0", currency: "USD" }, percent: 0.0 }
        },
        {
          date: Date.current,
          value: { amount: "200.0", currency: "USD" },
          trend: { favorable_direction: "up", direction: "up", value: { amount: "100.0", currency: "USD" }, percent: 100.0 }
        }
      ],
      trend: { favorable_direction: "up", direction: "up", value: { amount: "100.0", currency: "USD" }, percent: 100.0 },
      favorable_direction: "up"
    }.to_json

    series = TimeSeries.new([ { date: 1.day.ago.to_date, value: Money.new(100) }, { date: Date.current, value: Money.new(200) } ])

    assert_equal expected_values, series.to_json
  end

  test "numeric series can be serialized to json" do
    expected_values = {
      values: [
        { date: 1.day.ago.to_date, value: 100, trend: { favorable_direction: "up", direction: "flat", value: 0, percent: 0.0 } },
        { date: Date.current, value: 200, trend: { favorable_direction: "up", direction: "up", value: 100, percent: 100.0 } }
      ],
      trend: { favorable_direction: "up", direction: "up", value: 100, percent: 100.0 },
      favorable_direction: "up"
    }.to_json

    series = TimeSeries.new([ { date: 1.day.ago.to_date, value: 100 }, { date: Date.current, value: 200 } ])

    assert_equal expected_values, series.to_json
  end

  test "it does not accept invalid values in Time Series Trend" do
    error = assert_raises(ActiveModel::ValidationError) do
      TimeSeries.new(
        [
          { date: 1.day.ago.to_date, value: 100 },
          { date: Date.current, value: "two hundred" }
        ]
      )
    end
    assert_match(/Current must be of the same type as previous/, error.message)
    assert_match(/Previous must be of the same type as current/, error.message)
    assert_match(/Current must be of type Money, Numeric, or nil/, error.message)
  end


  test "it does not accept invalid values in Time Series Value" do
    # We need to stub trend otherwise an error is raised before TimeSeries::Value validation
    Trend.stub(:new, nil) do
      error = assert_raises(ActiveModel::ValidationError) do
        TimeSeries.new(
          [
            { date: 1.day.ago.to_date, value: 100 },
            { date: Date.current, value: "two hundred" }
          ]
        )
      end
      assert_equal "Validation failed: Value must be a Money or Numeric", error.message
    end
  end
end
