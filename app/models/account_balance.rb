class AccountBalance < ApplicationRecord
  belongs_to :account
  validates :account, :date, :balance, presence: true
  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }
end
