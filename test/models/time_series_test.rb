require "test_helper"

class TimeSeriesTest < ActiveSupport::TestCase
  test "it can accept array of money values" do
    series = TimeSeries.new([ { date: 1.day.ago, amount: Money.new(100) }, { date: Date.current, amount: Money.new(200) } ])

    assert_equal Money.new(100), series.first.value
    assert_equal Money.new(200), series.last.value
    assert_equal "normal", series.type
    assert_equal "up", series.trend.direction
    assert_equal Money.new(100), series.trend.value
    assert_equal 100.0, series.trend.percent
  end

  test "it can accept array of numeric values" do
    series = TimeSeries.new([ { date: 1.day.ago, amount: 100 }, { date: Date.current, amount: 200 } ])

    assert_equal 100, series.first.value
    assert_equal 200, series.last.value
    assert_equal "normal", series.type
    assert_equal "up", series.trend.direction
    assert_equal 100, series.trend.value
    assert_equal 100.0, series.trend.percent
  end

  test "when nil or empty array passed, it returns empty series" do
    series = TimeSeries.new(nil)
    assert_equal [], series.values

    series = TimeSeries.new([])

    assert_equal [], series.values
    assert_nil series.first
    assert_nil series.last
    assert_nil series.trend
    assert_equal({ values: [], trend: nil, type: "normal" }.to_json, series.to_json)
  end

  test "money series can be serialized to json" do
    expected_values = {
        values: [
            { date: 1.day.ago.to_date, value: { amount: 100, currency: "USD" }, trend: { type: "normal", direction: "flat", value: { amount: 0, currency: "USD" }, percent: 0 } },
            { date: Date.current, value: { amount: 200, currency: "USD" }, trend: { type: "normal", direction: "up", value: { amount: 100, currency: "USD" }, percent: 100.0 } }
        ],
        trend: { type: "normal", direction: "up", value: { amount: 100, currency: "USD" }, percent: 100.0 },
        type: "normal"
    }.to_json

    series = TimeSeries.new([ { date: 1.day.ago, amount: Money.new(100) }, { date: Date.current, amount: Money.new(200) } ])

    assert_equal expected_values, series.to_json
  end

  test "numeric series can be serialized to json" do
    expected_values = {
        values: [
            { date: 1.day.ago.to_date, value: 100, trend: { type: "normal", direction: "flat", value: 0, percent: 0 } },
            { date: Date.current, value: 200, trend: { type: "normal", direction: "up", value: 100, percent: 100.0 } }
        ],
        trend: { type: "normal", direction: "up", value: 100, percent: 100.0 },
        type: "normal"
    }.to_json

    series = TimeSeries.new([ { date: 1.day.ago, amount: 100 }, { date: Date.current, amount: 200 } ])

    assert_equal expected_values, series.to_json
  end
end
