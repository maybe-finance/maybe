require "test_helper"

class Account::ChartableTest < ActiveSupport::TestCase
  test "generates gapfilled balance series" do
    account = accounts(:depository)
    account.balances.delete_all

    account.balances.create!(date: 20.days.ago.to_date, balance: 5000, currency: "USD")
    account.balances.create!(date: 10.days.ago.to_date, balance: 5000, currency: "USD")

    period = Period.last_30_days
    series = account.balance_series(period: period)
    assert_equal period.days, series.values.count
    assert_equal 0, series.values.first.trend.current.amount
    assert_equal 5000, series.values.find { |v| v.date == 20.days.ago.to_date }.trend.current.amount
    assert_equal 5000, series.values.find { |v| v.date == 10.days.ago.to_date }.trend.current.amount
    assert_equal 5000, series.values.last.trend.current.amount
  end
end
