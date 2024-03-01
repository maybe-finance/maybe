class Family < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :accounts, dependent: :destroy
  has_many :transactions, through: :accounts

  # TODO: Add calculation
  def net_worth
    100000
  end

  def assets
    200000
  end

  def liabilities
    100000
  end

  # TODO: Replace test data with calculation
  def net_worth_series(period)
    {
      series_data: [
        { data: { date: 7.days.ago.to_date, balance: 50000 }, trend: { amount: 0, direction: "flat", percent: 0 } },
        { data: { date: 6.days.ago.to_date, balance: 50500 }, trend: { amount: 500, direction: "up", percent: 1 } },
        { data: { date: 5.days.ago.to_date, balance: 51000 }, trend: { amount: 500, direction: "up", percent: 0.99 } },
        { data: { date: 4.days.ago.to_date, balance: 51500 }, trend: { amount: 500, direction: "up", percent: 0.98 } },
        { data: { date: 3.days.ago.to_date, balance: 52000 }, trend: { amount: 500, direction: "up", percent: 0.97 } },
        { data: { date: 2.days.ago.to_date, balance: 52500 }, trend: { amount: 500, direction: "up", percent: 0.96 } },
        { data: { date: 1.day.ago.to_date, balance: 53000 }, trend: { amount: 500, direction: "up", percent: 0.95 } }
      ],
      last_balance: 53000,
      trend: Trend.new(current: 53000, previous: 50000, type: :asset)
    }
  end

  def asset_series(period)
    {
      series_data: [
        { data: { date: 7.days.ago.to_date, balance: 100000 }, trend: { amount: 0, direction: "flat", percent: 0 } },
        { data: { date: 6.days.ago.to_date, balance: 100500 }, trend: { amount: 500, direction: "up", percent: 1 } },
        { data: { date: 5.days.ago.to_date, balance: 101000 }, trend: { amount: 500, direction: "up", percent: 0.99 } },
        { data: { date: 4.days.ago.to_date, balance: 101500 }, trend: { amount: 500, direction: "up", percent: 0.98 } },
        { data: { date: 3.days.ago.to_date, balance: 102000 }, trend: { amount: 500, direction: "up", percent: 0.97 } },
        { data: { date: 2.days.ago.to_date, balance: 102500 }, trend: { amount: 500, direction: "up", percent: 0.96 } },
        { data: { date: 1.day.ago.to_date, balance: 103000 }, trend: { amount: 500, direction: "up", percent: 0.95 } }
      ],
      last_balance: 103000,
      trend: Trend.new(current: 103000, previous: 100000, type: :asset)
    }
  end

  def liability_series(period)
    {
      series_data: [
        { data: { date: 7.days.ago.to_date, balance: 50000 }, trend: { amount: 0, direction: "flat", percent: 0 } },
        { data: { date: 6.days.ago.to_date, balance: 50500 }, trend: { amount: 500, direction: "up", percent: 1 } },
        { data: { date: 5.days.ago.to_date, balance: 51000 }, trend: { amount: 500, direction: "up", percent: 0.99 } },
        { data: { date: 4.days.ago.to_date, balance: 51500 }, trend: { amount: 500, direction: "up", percent: 0.98 } },
        { data: { date: 3.days.ago.to_date, balance: 52000 }, trend: { amount: 500, direction: "up", percent: 0.97 } },
        { data: { date: 2.days.ago.to_date, balance: 52500 }, trend: { amount: 500, direction: "up", percent: 0.96 } },
        { data: { date: 1.day.ago.to_date, balance: 53000 }, trend: { amount: 500, direction: "up", percent: 0.95 } }
      ],
      last_balance: 53000,
      trend: Trend.new(current: 53000, previous: 50000, type: :liability)
    }
  end
end
