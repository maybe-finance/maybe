class Balance < ApplicationRecord
  include Monetizable

  belongs_to :account

  validates :account, :date, :balance, presence: true
  validates :flows_factor, inclusion: { in: [ -1, 1 ] }

  monetize :balance, :cash_balance,
           :start_cash_balance, :start_non_cash_balance, :start_balance,
           :cash_inflows, :cash_outflows, :non_cash_inflows, :non_cash_outflows, :net_market_flows,
           :cash_adjustments, :non_cash_adjustments,
           :end_cash_balance, :end_non_cash_balance, :end_balance

  scope :in_period, ->(period) { period.nil? ? all : where(date: period.date_range) }
  scope :chronological, -> { order(:date) }
end
