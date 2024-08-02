class Account::Holding < ApplicationRecord
  include Monetizable

  monetize :amount

  belongs_to :account
  belongs_to :security

  validates :qty, :currency, presence: true

  scope :chronological, -> { order(:date) }
  scope :current, -> { where(date: Date.current).order(amount: :desc) }
  scope :in_period, ->(period) { period.date_range.nil? ? all : where(date: period.date_range) }
  scope :known_value, -> { where.not(amount: nil) }
  scope :for, ->(security) { where(security_id: security).order(:date) }

  delegate :name, to: :security
  delegate :ticker, to: :security

  def weight
    return nil unless amount

    portfolio_value = account.holdings.current.known_value.sum(&:amount)
    portfolio_value.zero? ? 1 : amount / portfolio_value * 100
  end

  # Basic approximation of cost-basis
  def avg_cost
    avg_cost = account.holdings.for(security).where("date <= ?", date).average(:price)
    Money.new(avg_cost, currency)
  end

  def trend
    @trend ||= calculate_trend
  end

  private

    def calculate_trend
      return nil unless amount_money

      start_amount = qty * avg_cost

      TimeSeries::Trend.new \
        current: amount_money,
        previous: start_amount
    end
end
