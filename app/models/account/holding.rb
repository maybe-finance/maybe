class Account::Holding < ApplicationRecord
  include Monetizable

  monetize :amount

  belongs_to :account
  belongs_to :security

  validates :qty, :currency, presence: true

  scope :chronological, -> { order(:date) }
  scope :for, ->(security) { where(security_id: security).order(:date) }

  delegate :ticker, to: :security

  def name
    security.name || ticker
  end

  def weight
    return nil unless amount
    return 0 if amount.zero?

    account.balance.zero? ? 1 : amount / account.balance * 100
  end

  # Basic approximation of cost-basis
  def avg_cost
    avg_cost = account.holdings.for(security).where(currency: currency).where("date <= ?", date).average(:price)
    Money.new(avg_cost, currency)
  end

  def trend
    @trend ||= calculate_trend
  end

  def trades
    account.entries.where(entryable: account.trades.where(security: security)).reverse_chronological
  end

  def destroy_holding_and_entries!
    transaction do
      account.entries.where(entryable: account.trades.where(security: security)).destroy_all
      destroy
    end

    account.sync_later
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
