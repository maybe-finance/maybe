class AccountBalance < ApplicationRecord
  belongs_to :account

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def self.trend(account, period = Period.all)
    first = in_period(period).order(:date).first
    last = in_period(period).order(date: :desc).first
    Trend.new(current: last.balance, previous: first.balance, type: account.classification)
  end

  def self.to_series(account, period = Period.all)
    MoneySeries.new(
      in_period(period).order(:date),
      { trend_type: account.classification }
    )
  end
end
