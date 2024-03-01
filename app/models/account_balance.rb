class AccountBalance < ApplicationRecord
  belongs_to :account

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def trend(previous)
    Trend.new(current: balance, previous: previous&.balance, type: account.classification)
  end
end
