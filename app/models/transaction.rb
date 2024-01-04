class Transaction < ApplicationRecord
  belongs_to :account
  belongs_to :family

  def inflow?
    amount > 0
  end

  def outflow?
    amount < 0
  end
end
