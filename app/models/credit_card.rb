class CreditCard < ApplicationRecord
  include Accountable

  def available_credit_money
    available_credit ? Money.new(available_credit, account.currency) : nil
  end

  def minimum_payment_money
    minimum_payment ? Money.new(minimum_payment, account.currency) : nil
  end

  def annual_fee_money
    annual_fee ? Money.new(annual_fee, account.currency) : nil
  end

  class << self
    def color
      "#F13636"
    end
  end

  def color
    self.class.color
  end

  def icon
    "credit-card"
  end
end
