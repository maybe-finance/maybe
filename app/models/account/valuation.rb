class Account::Valuation < ApplicationRecord
  include Monetizable

  belongs_to :account
  validates :account, :date, :value, presence: true
  monetize :value

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def self.to_series
    TimeSeries.from_collection all, :value_money
  end
end
