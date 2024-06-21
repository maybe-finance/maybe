class Account::Valuation < ApplicationRecord
  include Monetizable

  belongs_to :account
  validates :account, :date, :value, presence: true
  validates :date, uniqueness: { scope: :account_id }
  monetize :value

  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }

  def trend
    TimeSeries::Trend.new current: 0, previous: 0
  end

  def first_of_series?
    account.valuations.order(:date).limit(1).pluck(:date).first == self.date
  end

  def last_of_series?
    account.valuations.order(date: :desc).limit(1).pluck(:date).first == self.date
  end

  def self.to_series
    TimeSeries.from_collection all, :value_money
  end

  def sync_account_later
    if destroyed?
      sync_start_date = previous_valuation_date
    else
      sync_start_date = [ date_previously_was, date ].compact.min
    end

    account.sync_later(sync_start_date)
  end

  private

    def previous_valuation_date
      self.account
          .valuations
          .where("date < ?", date)
          .order(date: :desc)
          .first&.date
    end
end
