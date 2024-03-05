require "test_helper"

class TrendTest < ActiveSupport::TestCase
  test "up" do
    trend = Trend.new(current: 100, previous: 50)
    assert_equal "up", trend.direction
  end

  test "down" do
    trend = Trend.new(current: 50, previous: 100)
    assert_equal "down", trend.direction
  end

  test "flat" do
    trend = Trend.new(current: 100, previous: 100)
    assert_equal "flat", trend.direction
  end

  test "infinitely up" do
    trend1 = Trend.new(current: 100, previous: nil)
    trend2 = Trend.new(current: 100, previous: 0)
    assert_equal "up", trend1.direction
    assert_equal "up", trend2.direction
  end

  test "infinitely down" do
    trend1 = Trend.new(current: nil, previous: 100)
    trend2 = Trend.new(current: 0, previous: 100)
    assert_equal "down", trend1.direction
    assert_equal "down", trend2.direction
  end

  test "empty" do
    trend = Trend.new
    assert_equal "flat", trend.direction
  end
end
