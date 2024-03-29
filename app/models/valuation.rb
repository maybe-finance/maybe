class Valuation < ApplicationRecord
  include Monetizable

  belongs_to :account
  validates :account, :date, :value, presence: true
  monetize :value

  after_commit :sync_account

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def self.to_series
    TimeSeries.from_collection all, :value_money
  end

  private
    def sync_account
      self.account.sync_later
    end
end
