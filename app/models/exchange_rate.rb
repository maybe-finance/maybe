class ExchangeRate < ApplicationRecord
  include Provided

  validates :from_currency, :to_currency, :date, :rate, presence: true
end
