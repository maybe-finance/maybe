class Trade < ApplicationRecord
  include Entryable, Monetizable

  monetize :price

  belongs_to :security

  validates :qty, presence: true
  validates :price, :currency, presence: true

  def unrealized_gain_loss
    return nil if qty.negative?
    current_price = security.current_price
    return nil if current_price.nil?

    current_value = current_price * qty.abs
    cost_basis = price_money * qty.abs

    Trend.new(current: current_value, previous: cost_basis)
  end
end
