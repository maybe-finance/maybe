require "test_helper"

class TimeSeries::TrendTest < ActiveSupport::TestCase
  test "handles money trend" do
    trend = TimeSeries::Trend.new(current: Money.new(100), previous: Money.new(50))
    assert_equal "up", trend.direction
    assert_equal Money.new(50), trend.value
    assert_equal 100.0, trend.percent
  end

  test "up" do
    assert_equal "up", TimeSeries::Trend.new(current: 100, previous: 50).direction
  end

  test "down" do
    assert_equal "down", TimeSeries::Trend.new(current: 50, previous: 100).direction
  end

  test "flat" do
    assert_equal "flat", TimeSeries::Trend.new(current: 100, previous: 100).direction
    assert_equal "flat", TimeSeries::Trend.new(current: 100, previous: nil).direction
  end

  test "infinitely up" do
    assert_equal "up", TimeSeries::Trend.new(current: 100, previous: 0).direction
  end

  test "infinitely down" do
    assert_equal "down", TimeSeries::Trend.new(current: nil, previous: 100).direction
    assert_equal "down", TimeSeries::Trend.new(current: 0, previous: 100).direction
  end

  test "empty" do
    assert_equal "flat", TimeSeries::Trend.new(current: nil, previous: nil).direction
  end
end
