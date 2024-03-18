class AccountBalance < ApplicationRecord
  include Monetizable

  belongs_to :account
  validates :account, :date, :balance, presence: true
  monetize :balance

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def self.to_series(account, period = Period.all)
    MoneySeries.new(
      in_period(period).order(:date),
      { trend_type: account.classification }
    )
  end
end
