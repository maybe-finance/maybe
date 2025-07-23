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

  def balance_trend
    Trend.new(
      current: end_balance_money,
      previous: start_balance_money,
      favorable_direction: favorable_direction
    )
  end

  private

    def favorable_direction
      flows_factor == -1 ? "down" : "up"
    end
end
