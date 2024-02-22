class AccountBalance < ApplicationRecord
  belongs_to :account

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def trend(previous)
    Trend.new(balance, previous&.balance)
  end
end
