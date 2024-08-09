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
end
