require "test_helper"

class TimeSeries::TrendTest < ActiveSupport::TestCase
  test "handles money trend" do
    trend = TimeSeries::Trend.new(current: Money.new(100), previous: Money.new(50))
    assert_equal "up", trend.direction
    assert_equal Money.new(50), trend.value
    assert_equal 100.0, trend.percent
  end

  test "up" do
    trend = TimeSeries::Trend.new(current: 100, previous: 50)
    assert_equal "up", trend.direction
    assert_equal "#10A861", trend.color
  end

  test "down" do
    trend = TimeSeries::Trend.new(current: 50, previous: 100)
    assert_equal "down", trend.direction
    assert_equal "#F13636", trend.color
  end

  test "flat" do
    trend1 = TimeSeries::Trend.new(current: 100, previous: 100)
    trend2 = TimeSeries::Trend.new(current: 100, previous: nil)
    trend3 = TimeSeries::Trend.new(current: nil, previous: nil)
    assert_equal "flat", trend1.direction
    assert_equal "flat", trend2.direction
    assert_equal "flat", trend3.direction
    assert_equal "#737373", trend1.color
  end

  test "infinitely up" do
    trend = TimeSeries::Trend.new(current: 100, previous: 0)
    assert_equal "up", trend.direction
  end

  test "infinitely down" do
    trend1 = TimeSeries::Trend.new(current: nil, previous: 100)
    trend2 = TimeSeries::Trend.new(current: 0, previous: 100)
    assert_equal "down", trend1.direction
    assert_equal "down", trend2.direction
  end

  test "empty" do
    trend = TimeSeries::Trend.new(current: nil, previous: nil)
    assert_equal "flat", trend.direction
  end
end
