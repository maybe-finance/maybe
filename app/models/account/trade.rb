class Account::Trade < ApplicationRecord
  include Account::Entryable, Monetizable

  monetize :price

  belongs_to :security

  validates :qty, presence: true, numericality: { other_than: 0 }
  validates :price, :currency, presence: true

  class << self
    def search(_params)
      all
    end

    def requires_search?(_params)
      false
    end
  end

  def sell?
    qty < 0
  end

  def buy?
    qty > 0
  end

  def unrealized_gain_loss
    return nil if sell?
    current_price = security.current_price
    return nil if current_price.nil?

    current_value = current_price * qty.abs
    cost_basis = price_money * qty.abs

    TimeSeries::Trend.new(current: current_value, previous: cost_basis)
  end
end
