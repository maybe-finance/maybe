class Balance < ApplicationRecord
  include Monetizable

  belongs_to :account
  validates :account, :date, :balance, presence: true
  monetize :balance
  scope :in_period, ->(period) { period.nil? ? all : where(date: period.date_range) }
  scope :chronological, -> { order(:date) }
end
