class AccountBalance < ApplicationRecord
  include Monetizable

  belongs_to :account
  validates :account, :date, :balance, presence: true
  monetize :balance

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }
end
