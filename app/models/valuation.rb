class Valuation < ApplicationRecord
  belongs_to :account

  after_commit :sync_account

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def self.trend(account, period = Period.all)
    first = in_period(period).order(:date).first
    last = in_period(period).order(date: :desc).last
    Trend.new(current: last.value, previous: first.value, type: account.classification)
  end

  def self.to_series(account, period = Period.all)
    MoneySeries.new(
      in_period(period).order(:date),
      { trend_type: account.classification, amount_accessor: :value }
    )
  end

  private
    def sync_account
      self.account.sync_later
    end
end
